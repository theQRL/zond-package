# One of these will be created per node we're trying to start
def new_keystore_files(
    files_artifact_uuid,
    qrysm_relative_dirpath,
):
    return struct(
        files_artifact_uuid=files_artifact_uuid,
        # ------------ All directories below are relative to the root of the files artifact ----------------
        qrysm_relative_dirpath=qrysm_relative_dirpath,
    )
