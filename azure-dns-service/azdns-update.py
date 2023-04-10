#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from __future__ import annotations

from argparse import ArgumentParser
from itertools import cycle
from os import getenv
from random import shuffle
from time import sleep
from typing import Union, Generator
from urllib.request import urlopen

from azure.identity import DefaultAzureCredential
from azure.mgmt.dns import DnsManagementClient

p = ArgumentParser()
# p.add_argument("-c", "--client-id", required= not getenv("AZURE_CLIENT_ID"), default=getenv("AZURE_CLIENT_ID"), help="App Reg/Svc Principal Client ID  (env: AZURE_CLIENT_ID)")
# p.add_argument("-i", "--client-secret", required= not getenv("AZURE_CLIENT_SECRET"),default=getenv("AZURE_CLIENT_SECRET"), help="App Reg/Svc Principal Client secret (env: AZURE_CLIENT_SECRET)")
p.add_argument(
    "-z",
    "--dns-zone",
    required=not getenv("AZURE_DNS_ZONE"),
    default=getenv("AZURE_DNS_ZONE"),
    help="Public DNS Zone Name (env: AZURE_DNS_ZONE)",
)
p.add_argument(
    "-g",
    "--resource-group",
    required=not getenv("AZURE_RESOURCE_GROUP"),
    default=getenv("AZURE_RESOURCE_GROUP"),
    help="DNS Zone Resource Group (env: AZURE_RESOURCE_GROUP)",
)
p.add_argument(
    "-s",
    "--subscription-id",
    required=not getenv("AZURE_SUBSCRIPTION_ID"),
    default=getenv("AZURE_SUBSCRIPTION_ID"),
    help="Azure Subscription ID (env: AZURE_SUBSCRIPTION_ID)",
)
p.add_argument("--record-names", required=True, nargs='+', default=[], help="One or more space-separated DNS record set to update/create")
# Optional Args
p.add_argument(
    "-i",
    "--static-ip",
    default=getenv("STATIC_IP"),
    required=False,
    help="Don't get public ip address. Use the provided static IP address",
)
p.add_argument("--run-once", default=False, required=False, action="store_true", help="Will run once and exit")
p.add_argument(
    "-t", "--interval", required=False, default=30, type=int, help="Interval in seconds between each DNS/IP request"
)
# p.add_argument("-t", "--tenant-id", default=getenv("AZURE_TENANT_ID"), help="Azure Tenant ID (env: AZURE_TENANT_ID)")

# p.print_help()
args = p.parse_args()


def get_next_public_ip(static_ip: str = "") -> Generator:
    str_not_blank = lambda s: bool(s and not s.isspace())
    # If a static ip is provided then use that always
    if str_not_blank(static_ip):
        print(f"Using provided static IP address {static_ip}")
        while True:
            yield static_ip
    list_of_providers = [
        "https://checkip.amazonaws.com",
        "https://ifconfig.me",
        "https://v4.ident.me/",
        "https://ipgrab.io",
        "https://myip.dnsomatic.com",
        "https://api.ipify.org",
        "https://ipecho.net/plain",
        "https://icanhazip.com",
    ]
    # Shuffle to make sure we don't always hit in a specific pattern
    shuffle(list_of_providers)
    # Circle back to first element so we have an endless fake-pool of providers
    circularList = cycle(list_of_providers)
    while True:
        next_provider = next(circularList)
        ip: str = urlopen(next_provider).read().decode("UTF-8").strip()
        print(f"Got public IP '{ip}', from provider: {next_provider}")
        yield ip


credentials: DefaultAzureCredential = DefaultAzureCredential(
    exclude_cli_credential=True,
    exclude_interactive_browser_credential=True,
    exclude_visual_studio_code_credential=True,
)
dns_client: DnsManagementClient = DnsManagementClient(credentials, args.subscription_id)

ip_provider_index = 0

# # First get record-set
# record_set:Union[object, RecordSet]  = None
# try:
# 	record_set = dns_client.record_sets.get(args.resource_group, args.dns_zone, args.record_names, 'A')
# except HttpResponseError as e:
# 	# Record not found or some problem?!
# 	pass

old_ip_addr: Union[str, object] = None
print(
    f"""App Args:
  Run once     : {args.run_once}
  Rsc Group    : {args.resource_group}
  DNS Zone     : {args.dns_zone}
  Record Name  : {args.record_names}
  IP Address   : {'Public' if args.static_ip == '' else args.static_ip}
  Internal     : {args.interval}
"""
)
# TENANT_ID    : {getenv('AZURE_TENANT_ID')}
# CLIENIT ID   : {getenv('AZURE_CLIENT_ID')}
# CLIENT_SECRET: {getenv('AZURE_CLIENT_SECRET')}
while True:  # Infinite loop
    new_ip_addr: str = next(get_next_public_ip(args.static_ip))
    if old_ip_addr != new_ip_addr:
        parameter_record = {"ttl": 300, "a_records": [{"ipv4_address": f"{new_ip_addr}"}]}
        old_ip_addr = new_ip_addr
        for record in args.record_names:
            dns_client.record_sets.create_or_update(args.resource_group, args.dns_zone, record, "A", parameter_record)  # type: ignore
        print(f"Updating DNS record {args.record_names}.{args.dns_zone} with IP ({new_ip_addr})")
    else:
        print("Skipping: new IP is same as old IP")
    if args.run_once:
        break
    sleep(args.interval)
