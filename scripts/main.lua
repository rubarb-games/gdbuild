local c = require("scripts/common")

-- ATM, create_config works one single config. A future version could
-- support writing multiple configs. By giving each one a unique id,
-- the could be created on the odin side.
-- set_folder_project(0, "...")

-- One config per build. Multiple deployments
-- Should get access to command args
function create_config()
	version_repo("git@github.com:rubarb-games/basalt-01-version.git")
	project_folder(".")
	godot_version("4.6.1-stable")
	project_repo_url("git@github.com:rubarb-games/basalt-01.git")
	godot_preprocessor("build-script/preprocess.gd")
end

-- will need access to cmd args, config and whatever else
function create_export_preset()
	-- name("Thomas's Super Game")
	-- platform("Quantum computer")

	export_dir("src")
	-- export_file("file.txt")
end
