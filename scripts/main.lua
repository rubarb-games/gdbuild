
function create_config(cfg)
	set_folder_project(cfg, "./project_root")
end

-- will need access to cmd args, config and whatever else
function export_preset(ep)
	set_name(ep, "Thomas's Super Game")
	set_platform(ep, "Quantum computer")
end
