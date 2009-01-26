/* watrayproject.vala
 *
 * Copyright (C) 2009  Matias De la Puente
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
using Gtk;

public errordomain Watray.ProjectError
{
	PROJECT_NOT_ADDED,
	WRONG_ITEM_PATH,
}

public class Watray.Project: GLib.Object
{
	private Gtk.TreeIter? _iter = null;
	private TreeStore _projects_store = null;
	
	public string name { set; get; }
	
	public signal void selected ();
	public signal void activated ();
	public signal void removed ();
	public signal void item_selected (ItemInfo item_info);
	public signal void item_activated (ItemInfo item_info);
	public signal void item_removed (ItemInfo item_info);
	
	public Project (string name)
	{
		this.name = name;
	}
	
	internal void add_to_projects_store (TreeStore projects_store)
	{
		return_if_fail (_projects_store == null);
		_projects_store = projects_store;
		_projects_store.append (out _iter, null);
		_projects_store.set (_iter, Columns.STOCK_ID, STOCK_DIRECTORY, Columns.ITEM_NAME, this.name, Columns.PROJECT, this, -1);
	}
	
	internal void remove_from_projects_store () throws ProjectError
	{
		return_if_fail (_projects_store == null);
		if (_projects_store.iter_has_child (_iter))
			empty_item ("/");
		_projects_store.remove (_iter);
		this.removed ();
		_iter = null;
		_projects_store = null;
	}
	
	public void create_item (string item_path, ItemInfo? item_info = null) throws ProjectError
	{
		var parent_iter = get_iter_from_item_path (Path.get_dirname (item_path));
		TreeIter new_item_iter;
		_projects_store.append (out new_item_iter, parent_iter);
		_projects_store.set (new_item_iter, Columns.ITEM_NAME, Path.get_basename (item_path), Columns.PROJECT, this, Columns.ITEM_INFO, item_info);
	}
	
	public void create_item_from_stock (string item_path, string stock_id, ItemInfo? item_info = null) throws ProjectError
	{
		var parent_iter = get_iter_from_item_path (Path.get_dirname (item_path));
		TreeIter new_item_iter;
		_projects_store.append (out new_item_iter, parent_iter);
		_projects_store.set (new_item_iter, Columns.STOCK_ID, stock_id, Columns.ITEM_NAME, Path.get_basename (item_path), Columns.PROJECT, this, Columns.ITEM_INFO, item_info);
	}
	
	public void create_item_from_pixbuf (string item_path, Gdk.Pixbuf pixbuf, ItemInfo? item_info = null) throws ProjectError
	{
		var parent_iter = get_iter_from_item_path (Path.get_dirname (item_path));
		TreeIter new_item_iter;
		_projects_store.append (out new_item_iter, parent_iter);
		_projects_store.set (new_item_iter, Columns.PIXBUF, pixbuf, Columns.ITEM_NAME, Path.get_basename (item_path), Columns.PROJECT, this, Columns.ITEM_INFO, item_info);
	}
	
	public void remove_item (string item_path) throws ProjectError
	{
		var iter = get_iter_from_item_path (item_path);
		if (_projects_store.iter_has_child (iter))
			empty_item (item_path);
		ItemInfo item_info;
		_projects_store.get (iter, Columns.ITEM_INFO, out item_info);
		_projects_store.remove (iter);
		item_info.path = item_path;
		this.item_removed (item_info);
	}
	
	public void empty_item (string item_path) throws ProjectError
	{
		TreeIter iter;
		string item_name;
		ItemInfo item_info;
		var parent_iter = get_iter_from_item_path (item_path);
		while (_projects_store.iter_children (out iter, parent_iter))
		{
			_projects_store.get (iter, Columns.ITEM_NAME, out item_name, Columns.ITEM_INFO, out item_info);
			if (_projects_store.iter_has_child (iter))
				empty_item (item_path + "/" + item_name);
			_projects_store.remove (iter);
			item_info.path = item_path + "/" + item_name;
			this.item_removed (item_info);
		}
	}

	public void set (string item_path, ItemInfo item_info) throws ProjectError
	{
		var iter = get_iter_from_item_path (item_path);
		_projects_store.set (iter, Columns.ITEM_INFO, item_info);
	}
	
	public ItemInfo get (string item_path) throws ProjectError
	{
		var iter = get_iter_from_item_path (item_path);
		ItemInfo item_info;
		_projects_store.get (iter, Columns.ITEM_INFO, out item_info);
		item_info.path = item_path;
		return item_info;
	}
	
	public void set_item_icon_from_stock (string item_path, string stock_id) throws ProjectError
	{
		var item_iter = get_iter_from_item_path (item_path);
		_projects_store.set (item_iter, Columns.STOCK_ID, stock_id);
	}
	
	public void set_item_icon_from_pixbuf (string item_path, Gdk.Pixbuf pixbuf) throws ProjectError
	{
		var item_iter = get_iter_from_item_path (item_path);
		_projects_store.set (item_iter, Columns.PIXBUF, pixbuf);
	}
	
	private TreeIter? get_iter_from_item_path (string item_path) throws ProjectError
	{
		if (_iter == null || _projects_store == null)
			throw new ProjectError.PROJECT_NOT_ADDED ("The project %s was not added", this.name);
		TreeIter parent_iter = _iter;
		if (item_path == "/")
			return parent_iter;
		foreach (string item_name in item_path.split ("/"))
		{
			if (item_name!="")
			{
				if (!_projects_store.iter_has_child (parent_iter))
					throw new ProjectError.WRONG_ITEM_PATH ("Item %s not founded", item_name);
				TreeIter iter;
				bool item_founded = false;
				for (int i=0; i<_projects_store.iter_n_children (parent_iter); i++)
				{
					string name;
					_projects_store.iter_nth_child (out iter, parent_iter, i);
					_projects_store.get (iter, Columns.ITEM_NAME, out name);
					if (name==item_name)
					{
						item_founded = true;
						parent_iter = iter;
						break;
					}
				}
				if (!item_founded)
					throw new ProjectError.WRONG_ITEM_PATH ("Item %s not founded", item_name);
			}
		}
		return parent_iter;
	}
}

