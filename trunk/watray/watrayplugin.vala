/* watrayplugin.vala
 *
 * Copyright (C) 2008-2009  Matias De la Puente
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Matias De la Puente <mfpuente.ar@gmail.com>
 */

internal class Watray.Plugin : GLib.Object
{
	private Module module;
	private Type type;
	private IPlugin activated_plugin;

	private delegate Type PluginFunction ();
	
	public PluginInfo plugin_info { private set; get; }
	public bool is_activated { private set; get; }
	public bool is_loaded { private set; get; }
	
	public Plugin (PluginInfo plugin_info)
	{
		this.plugin_info = plugin_info;
	}
	
	public bool load ()
	{
		if (this.is_loaded)
			return true;
		string plugin_filename = Module.build_path (plugin_info.path, plugin_info.module);
		this.module = Module.open (plugin_filename, ModuleFlags.BIND_LAZY);
		if (module == null)
			return false;
		
		void* function;
		this.module.symbol ("register_watray_plugin", out function);
		
		var register_plugin = (PluginFunction)function;
		
		this.type = register_plugin ();
		this.is_loaded = true;
		return true;
	}
	
	public bool activate (IMainWindow main_window, IProjectsPanel projects_panel, IDocumentsPanel documents_panel)
	{
		if (!this.is_loaded)
			return false;
		if (this.is_activated)
			return true;
		activated_plugin = (IPlugin)Object.new (this.type, "main-window", main_window, "projects-panel", projects_panel, "documents-panel", documents_panel, null);
		if (activated_plugin == null)
			return false;
		this.is_activated = true;
		return true;
	}
	
	public void deactivate ()
	{
		this.activated_plugin == null;
		this.is_activated = false;
	}
}