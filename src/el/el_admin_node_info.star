def get_qnode_qnr_for_node(plan, service_name, port_id):
    recipe = PostHttpRequestRecipe(
        endpoint="",
        body='{"method":"admin_nodeInfo","params":[],"id":1,"jsonrpc":"2.0"}',
        content_type="application/json",
        port_id=port_id,
        extract={
            "qnode": """.result.qnode | split("?") | .[0]""",
            "qnr": ".result.qnr",
        },
    )
    response = plan.wait(
        recipe=recipe,
        field="extract.qnode",
        assertion="!=",
        target_value="",
        timeout="15m",
        service_name=service_name,
    )
    return (response["extract.qnode"], response["extract.qnr"])


def get_qnode_for_node(plan, service_name, port_id):
    recipe = PostHttpRequestRecipe(
        endpoint="",
        body='{"method":"admin_nodeInfo","params":[],"id":1,"jsonrpc":"2.0"}',
        content_type="application/json",
        port_id=port_id,
        extract={
            "qnode": """.result.qnode | split("?") | .[0]""",
        },
    )
    response = plan.wait(
        recipe=recipe,
        field="extract.qnode",
        assertion="!=",
        target_value="",
        timeout="15m",
        service_name=service_name,
    )
    return response["extract.qnode"]
