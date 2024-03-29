/* simpledocumentmanager.vala
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
using Watray;
using Gtk;
using Gee;

public class Simple.DocumentManager : GLib.Object
{
	private IMainWindow _main_window;
	private IDocumentsPanel _documents_panel;
	private IProjectsPanel _projects_panel;
	private ConfigureManager _configure_manager;
	private ActionGroup _action_group;
	private string _current_dir;
	private HashMap<string, DocumentView> _views;
	private Project _opened_files;
	
	private uint _ui_id;
	private const string _ui = """
	<ui>
		<menubar name="MainMenu">
			<menu name="FileMenu" action="FileMenuAction">
				<menu name="NewMenu" action="NewMenuAction">
					<placeholder name="NewMenuOps">
						<menuitem action="NewTextFileAction"/>
					</placeholder>
				</menu>
				<menu name="OpenMenu" action="OpenMenuAction">
					<placeholder name="OpenMenuOps">
						<menuitem action="OpenTextFileAction"/>
					</placeholder>
				</menu>
			</menu>
			<menu name="ViewMenu" action="ViewMenuAction">
				<placeholder name="ViewOps">
					<menuitem name="ViewTextFiles" action="ViewTextFilesAction"/>
				</placeholder>
			</menu>
		</menubar>
		<popup name="NewPopup" action="NewPopupAction">
			<placeholder name="NewPopupOps">
				<menuitem action="NewTextFileAction"/>
			</placeholder>
		</popup>
		<popup name="OpenPopup" action="OpenPopupAction">
			<placeholder name="OpenPopupOps">
				<menuitem action="OpenTextFileAction"/>
			</placeholder>
		</popup>
	</ui>""";
	
	private const ActionEntry[] _action_entries =
	{
		{ "NewTextFileAction", STOCK_FILE, N_("Text file"), null, null, on_new},
		{ "OpenTextFileAction", STOCK_FILE, N_("Text file"), null, null, on_open}
	};
	
	private const ToggleActionEntry[] _toggle_action_entries =
	{
		{ "ViewTextFilesAction", null, N_("Opened text files"), null, null, on_show_text_files, false }
	};

	public DocumentManager (IMainWindow main_window, IDocumentsPanel documents_panel, IProjectsPanel projects_panel, ConfigureManager configure_manager)
	{
		_main_window = main_window;
		_documents_panel = documents_panel;
		_projects_panel = projects_panel;
		_configure_manager = configure_manager;
		_current_dir = Environment.get_home_dir ();
		_views = new HashMap<string, DocumentView> (str_hash, str_equal);
		_opened_files = new Project (_("Opened text files"));
		
		_action_group = new ActionGroup ("SimplePluginActions");
		_action_group.set_translation_domain (Config.GETTEXT_PACKAGE);
		_action_group.add_actions (_action_entries, this);
		_action_group.add_toggle_actions (_toggle_action_entries, this);
		
		var ui_manager = _main_window.get_ui_manager ();
		ui_manager.insert_action_group (_action_group, -1);
		_ui_id = ui_manager.add_ui_from_string (_ui, -1);
		
		_configure_manager.notify["text-files-visible"] += () => {
			update_text_files_visibility ();
		};
		
		update_text_files_visibility ();
		
		_opened_files.item_selected += (project, item_path) => {
			var file = _opened_files[item_path];
			var view = _views[file.get_string ()];
			_documents_panel.show_view (view);
		};
		
		_documents_panel.view_selected += (panel, view) => {
			if (view is DocumentView && _configure_manager.text_files_visible)
				_opened_files.select_item (((DocumentView)view).item_path);
		};
	}
	
	~DocumentManager ()
	{
		var ui_manager = _main_window.get_ui_manager ();
		ui_manager.remove_ui (_ui_id);
	}
	
	public void on_new ()
	{
		int i = 0;
		string filename = _current_dir + "/" + _("Unsaved text file %i");
		while (_views.contains (filename.printf (++i)))
			;
		var view = new DocumentView (filename.printf (i), _configure_manager);
		view.save_as = true;
		view.save_action += (document_view) => {
			if (document_view.save_as)
				on_save_as_document (document_view);
			else
				document_view.save ();
		};
		view.save_as_action += on_save_as_document;
		view.close_action += on_close_document;
		_views[view.filename] = view;
		if (_configure_manager.text_files_visible)
		{
			Value? data = Value (typeof(string));
			data.set_string (view.filename);
			while (_opened_files.item_exist (view.item_path))
				view.item_path += "+";
			_opened_files.create_item_from_stock (view.item_path, STOCK_FILE, data);
		}
		_documents_panel.add_view (view);
		_documents_panel.show_view (view);
	}
	
	public void on_open ()
	{
		var dialog = new FileChooserDialog (_("Open"), null, FileChooserAction.OPEN);
		dialog.set_current_folder (_current_dir);
		dialog.add_button (STOCK_CANCEL, ResponseType.CANCEL);
		dialog.add_button (STOCK_OPEN, ResponseType.OK);
		dialog.set_default_response (ResponseType.OK);
		var filter = new FileFilter ();
		filter.set_name (_("All files"));
		filter.add_pattern ("*");
		dialog.add_filter (filter);
		
		if (dialog.run ()==ResponseType.OK)
		{
			DocumentView view;
			if (!_views.contains (dialog.get_filename ()))
			{
				view = new DocumentView (dialog.get_filename (), _configure_manager);
				view.save_action += (document_view) => { document_view.save (); };
				view.save_as_action += on_save_as_document;
				view.close_action += on_close_document;
				view.open ();
				_current_dir = dialog.get_current_folder ();
				_views[view.filename] = view;
				if (_configure_manager.text_files_visible)
				{
					Value? data = Value (typeof(string));
					data.set_string (view.filename);
					while (_opened_files.item_exist (view.item_path))
						view.item_path += "+";
					_opened_files.create_item_from_stock (view.item_path, STOCK_FILE, data);
				}
				_documents_panel.add_view (view);
			}
			else
				view = _views[dialog.get_filename ()];
			_documents_panel.show_view (view);
		}
		dialog.destroy ();
	}

	public void on_save_as_document (DocumentView view)
	{
		var dialog = new FileChooserDialog (_("Save file as"), null, FileChooserAction.SAVE);
		dialog.set_current_folder (Path.get_dirname (view.filename));
		dialog.add_button (STOCK_CANCEL, ResponseType.CANCEL);
		dialog.add_button (STOCK_SAVE, ResponseType.OK);
		dialog.set_default_response (ResponseType.OK);
		var filter = new FileFilter ();
		filter.set_name (_("All files"));
		filter.add_pattern ("*");
		dialog.add_filter (filter);
	
		if (dialog.run () == ResponseType.OK)
		{
			_views.remove (view.filename);
			view.filename = dialog.get_filename ();
			_views[view.filename] = view;
			view.save ();
			view.save_as = false;
			if (_configure_manager.text_files_visible)
			{
				_opened_files.remove_item (view.item_path);
				view.item_path = "/" + Path.get_basename (view.filename);
				Value? data = Value (typeof(string));
				data.set_string (view.filename);
				while (_opened_files.item_exist (view.item_path))
					view.item_path += "+";
				_opened_files.create_item_from_stock (view.item_path, STOCK_FILE, data);
			}
		}
		dialog.destroy ();
	}
	
	private void on_close_document (DocumentView document_view)
	{
		if (document_view.tab_mark)
		{
			var message = new MessageDialog (null, DialogFlags.MODAL, MessageType.WARNING, ButtonsType.NONE, _("Want to save the document %s?"), document_view.tab_text);
			message.add_button (STOCK_YES, ResponseType.YES);
			message.add_button (STOCK_NO, ResponseType.NO);
			message.add_button (STOCK_CANCEL, ResponseType.CANCEL);
			var response = message.run ();
			message.destroy ();
			
			if (response == ResponseType.CANCEL)
				return;
			
			if (response == ResponseType.YES)
				if (document_view.save_as)
					on_save_as_document (document_view);
				else
					document_view.save ();
		}
		_documents_panel.remove_view (document_view);
		if (_configure_manager.text_files_visible)
			_opened_files.remove_item (document_view.item_path);
		_views.remove (document_view.filename);
	}
	
	public void on_show_text_files ()
	{
		var toggle_action = (ToggleAction)_action_group.get_action ("ViewTextFilesAction");
		_configure_manager.text_files_visible = toggle_action.active;
	}
	
	private void update_text_files_visibility ()
	{
		if (_configure_manager.text_files_visible)
		{
			Value? data;
			_projects_panel.add_project (_opened_files);
			foreach (string filename in _views.get_keys ())
			{
				string item_path = "/" + Path.get_basename (filename);
				data = Value (typeof(string));
				data.set_string (filename);
				while (_opened_files.item_exist (item_path))
					item_path += "+";
				_opened_files.create_item_from_stock (item_path, STOCK_FILE, data);
			}
		}
		else
			_projects_panel.remove_project (_opened_files);
		
		var toggle_action = (ToggleAction)_action_group.get_action ("ViewTextFilesAction");
		toggle_action.active = _configure_manager.text_files_visible;
	}
}
