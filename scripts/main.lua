local c = require("scripts/common")

function create_config(args)
	c.hello()

	print("version: " .. get_version(args))
	print("dry:     " .. tostring(is_dry(args)))
	print("verbose: " .. tostring(is_verbose(args)))

	-- [REQUIRED] folder_project: string
	-- [REQUIRED] godot_version: string,
	-- [REQUIRED] repo_url: string,
	-- folder_output: string,
	-- repo_branch: string,
	-- repo_commit: string,
	-- preprocessor: string,
	-- path_log_build: string,
	-- path_log_preprocessor: string,
	-- path_log_export: string,
	-- path_log_deployment: string,

	-- TODO: how to handle buildnum?

	return {
		{
			folder_project = "./folder/sub_folder/project",
			godot_version = "4.7.1-stable",
			repo_url = "https://github.com/repo",
			path_log_build = "logs/log_build.log",
		},
		{},
	}
end

-- will need access to cmd args, config and whatever else
function export_preset(ep)
	set_name(ep, "Thomas's Super Game")
	set_platform(ep, "Quantum computer")
end
