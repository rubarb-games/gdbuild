local c = require("scripts/common")

-- ATM, create_config works one single config. A future version could
-- support writing multiple configs. By giving each one a unique id,
-- the could be created on the odin side.
-- set_folder_project(0, "...")

-- One config per build. Multiple deployments
function create_config(args)
	version_repo("git@github.com:rubarb-games/basalt-01-version.git")
	project_folder(".")
	godot_version("4.6.1-stable")
	project_repo_url("git@github.com:rubarb-games/basalt-01.git")
	godot_preprocessor("build-script/preprocess.gd")

	-- already here decide where to deploy? or deploy at all?
end

function create_export_preset(args, config, version)
	name("Thomas's Super Game")
	platform("Quantum computer")

	-- too verbose and hard to understand
	-- export_filter("exclude")
	-- export_dir("src")
	-- export_file("scripts/common.lua")
	-- what I want:
	exclude_dirs({
		"dev-tools",
		"temp",
		"build-scripts",
	})
	-- calling any include functions aftwards is illegal
	-- include_dirs(...) works only if export_filter is not set

	include_filter("*.toml,*.ini")

	script_export_mode("text") -- binary_token, compressed_binary_token

	texture_format_s3tc_bptc(true)
	texture_format_etc2_astc(false)
	shader_baker(true)

	application_icon("") -- res:// ?
	application_file_version(version.full_string)
end
