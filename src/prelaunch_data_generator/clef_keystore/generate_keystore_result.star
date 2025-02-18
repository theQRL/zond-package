# Package object containing information about the keystore that was generated for clef
def new_generate_keystore_result(
    keystore
):
    return struct(
        # Contains keystore for clef
        keystore=keystore,
    )
