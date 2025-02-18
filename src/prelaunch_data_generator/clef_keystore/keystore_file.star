def new_keystore_file(
    file_artifact_uuid,
    clef_relative_dirpath,
):
    return struct(
        file_artifact_uuid=file_artifact_uuid,
        # ------------ All directories below are relative to the root of the files artifact ----------------
        clef_relative_dirpath=clef_relative_dirpath,
    )
