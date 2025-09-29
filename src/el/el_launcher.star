constants = import_module("../package_io/constants.star")
input_parser = import_module("../package_io/input_parser.star")
shared_utils = import_module("../shared_utils/shared_utils.star")

gzond = import_module("./gzond/gzond_launcher.star")


def launch(
    plan,
    network_params,
    el_cl_data,
    jwt_file,
    participants,
    global_log_level,
    global_node_selectors,
    global_tolerations,
    persistent,
    network_id,
    num_participants,
    port_publisher,
    mev_builder_type,
    mev_params,
    remote_signer_context,
):
    el_launchers = {
        constants.EL_TYPE.gzond: {
            "launcher": gzond.new_gzond_launcher(
                el_cl_data,
                jwt_file,
                network_params.network,
                network_id,
                remote_signer_context,
                network_params.light_kdf_enabled,
            ),
            "launch_method": gzond.launch,
        },
    }

    all_el_contexts = []
    network_name = shared_utils.get_network_name(network_params.network)
    for index, participant in enumerate(participants):
        cl_type = participant.cl_type
        el_type = participant.el_type
        node_selectors = input_parser.get_client_node_selectors(
            participant.node_selectors,
            global_node_selectors,
        )
        tolerations = input_parser.get_client_tolerations(
            participant.el_tolerations, participant.tolerations, global_tolerations
        )

        if el_type not in el_launchers:
            fail(
                "Unsupported launcher '{0}', need one of '{1}'".format(
                    el_type, ",".join(el_launchers.keys())
                )
            )

        el_launcher, launch_method = (
            el_launchers[el_type]["launcher"],
            el_launchers[el_type]["launch_method"],
        )

        # Zero-pad the index using the calculated zfill value
        index_str = shared_utils.zfill_custom(index + 1, len(str(len(participants))))

        el_service_name = "el-{0}-{1}-{2}".format(index_str, el_type, cl_type)

        el_context = launch_method(
            plan,
            el_launcher,
            el_service_name,
            participant,
            global_log_level,
            all_el_contexts,
            persistent,
            tolerations,
            node_selectors,
            port_publisher,
            index,
        )
        # Add participant el additional prometheus metrics
        for metrics_info in el_context.el_metrics_info:
            if metrics_info != None:
                metrics_info["config"] = participant.prometheus_config

        all_el_contexts.append(el_context)

    plan.print("Successfully added {0} EL participants".format(num_participants))
    return all_el_contexts
