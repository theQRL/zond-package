web3signer = import_module("./web3signer/web3signer_launcher.star")
clef = import_module("./clef/clef_launcher.star")

constants = import_module("../package_io/constants.star")
input_parser = import_module("../package_io/input_parser.star")
node_metrics = import_module("../node_metrics_info.star")
remote_signer_context = import_module("./remote_signer_context.star")
shared_utils = import_module("../shared_utils/shared_utils.star")

def launch(
    plan,
    service_name,
    remote_signer_type,
    image,
    full_name,
    vc_type,
    node_keystore_files,
    participant,
    global_tolerations,
    node_selectors,
    port_publisher,
    remote_signer_index,
):
    plan.print("Launching remote signer")

    rs_launchers = {
        constants.REMOTE_SIGNER_TYPE.clef: {
            "launcher": clef.new_clef_launcher(),
            "launch_method": clef.launch,
        },
        # constants.REMOTE_SIGNER_TYPE.web3signer: {
        #     "launcher": web3signer.new_web3signer_launcher(),
        #     "launch_method": web3signer.launch,
        # },
    }

    tolerations = input_parser.get_client_tolerations(
        participant.remote_signer_tolerations,
        participant.tolerations,
        global_tolerations,
    )

    if remote_signer_type not in rs_launchers:
        fail(
            "Unsupported launcher '{0}', need one of '{1}'".format(
                remote_signer_type, ",".join(rs_launchers.keys())
            )
        )

    rs_launcher, launch_method = (
        rs_launchers[remote_signer_type]["launcher"],
        rs_launchers[remote_signer_type]["launch_method"],
    )

    # rs_context = launch_method(
    #     plan,
    #     rs_launcher,
    #     cl_service_name,
    #     participant,
    #     args_with_right_defaults.global_log_level,
    #     boot_cl_client_ctx,
    #     el_context,
    #     full_name,
    #     new_cl_node_validator_keystores,
    #     snooper_engine_context,
    #     persistent,
    #     tolerations,
    #     node_selectors,
    #     args_with_right_defaults.checkpoint_sync_enabled,
    #     checkpoint_sync_url,
    #     args_with_right_defaults.port_publisher,
    #     index,
    # )
    rs_context = None

    return rs_context
    