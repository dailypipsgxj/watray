/* simpledocumentview.vala
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

public class Simple.DocumentView : Watray.DocumentView
{
	private TextBuffer _text_buffer;
	private TextView _text_view;
	private ConfigureManager _configure_manager;
	private string _filename;

	public string filename
	{
		set
		{
			_filename = value;
			this.tab_text = Path.get_basename (_filename);
		}
		get { return _filename; }
	}
	public string item_path { set; get; }
	public bool save_as { set; get; }
	
	public DocumentView (string filename, ConfigureManager configure_manager)
	{
		this.filename = filename;
		_item_path = "/" + Path.get_basename (_filename);
		_configure_manager = configure_manager;
		
		_configure_manager.notify["text-font"] += () => {
			_text_view.modify_font (Pango.FontDescription.from_string (_configure_manager.text_font));
		};
		
		_text_buffer = new TextBuffer (null);
		_text_buffer.changed += () => { this.tab_mark = true; };
		_text_view = new TextView.with_buffer (_text_buffer);
		_text_view.modify_font (Pango.FontDescription.from_string (_configure_manager.text_font));
		
		var scrolled_window = new ScrolledWindow (null, null);
		scrolled_window.add (_text_view);
		scrolled_window.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		this.pack_start (scrolled_window, true, true, 5);

		this.copy_action += () => {
			var clipboard = _text_view.get_clipboard (Gdk.SELECTION_CLIPBOARD);
			_text_buffer.copy_clipboard (clipboard);
		};
		this.cut_action += () => {
			var clipboard = _text_view.get_clipboard (Gdk.SELECTION_CLIPBOARD);
			_text_buffer.cut_clipboard (clipboard, true);
		};
		this.paste_action += () => {
			var clipboard = _text_view.get_clipboard (Gdk.SELECTION_CLIPBOARD);
			_text_buffer.paste_clipboard (clipboard, null, true);
		};

		this.show_all ();
	}

	public void open ()
	{
		string text;
		return_if_fail (FileUtils.test (_filename, FileTest.EXISTS));
		try
		{
			FileUtils.get_contents (_filename, out text);
			_text_buffer.set_text (text, -1);
			this.tab_mark = false;
		}
		catch (FileError err)
		{
			print ("Error opening document: %s\n", err.message);
		}
	}

	public void save ()
	{
		TextIter start, end;
		_text_buffer.get_bounds (out start, out end);
		string text = _text_buffer.get_text (start, end, false);
		try
		{
			FileUtils.set_contents (_filename, text);
			this.tab_mark = false;
		}
		catch (FileError err)
		{
			print ("Error saving document: %s\n", err.message);
		}
	}
}

