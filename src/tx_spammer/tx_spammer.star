shared_utils = import_module("../shared_utils/shared_utils.star")
SERVICE_NAME = "tx_spammer"

# The min/max CPU/memory that tx spammer can use
MIN_CPU = 100
MAX_CPU = 1000
MIN_MEMORY = 20
MAX_MEMORY = 300


def launch_tx_spammer(
    plan,
    prefunded_addresses,
    all_el_contexts,
    tx_spammer_params,
    global_node_selectors,
):
    config = get_config(
        prefunded_addresses,
        all_el_contexts,
        tx_spammer_params,
        global_node_selectors,
    )
    plan.add_service(SERVICE_NAME, config)


def get_config(
    prefunded_addresses,
    all_el_contexts,
    tx_spammer_params,
    node_selectors,
):
    cmd = [
        "{}".format(tx_spammer_params.scenario),
        "--seed={}".format(prefunded_addresses[13].seed),
        "--rpchost={}".format(
            ",".join([el_context.rpc_http_url for el_context in all_el_contexts])
        ),
    ]

    if tx_spammer_params.throughput != None:
        cmd.append("--throughput={}".format(tx_spammer_params.throughput))

    if tx_spammer_params.max_pending != None:
        cmd.append("--max-pending={}".format(tx_spammer_params.max_pending))

    if tx_spammer_params.max_wallets != None:
        cmd.append("--max-wallets={}".format(tx_spammer_params.max_wallets))

    if len(tx_spammer_params.tx_spammer_extra_args) > 0:
        cmd.extend([param for param in tx_spammer_params.tx_spammer_extra_args])

    return ServiceConfig(
        image=tx_spammer_params.image,
        cmd=cmd,
        min_cpu=MIN_CPU,
        max_cpu=MAX_CPU,
        min_memory=MIN_MEMORY,
        max_memory=MAX_MEMORY,
        node_selectors=node_selectors,
    )
