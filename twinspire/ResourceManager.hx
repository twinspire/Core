/**
Copyright 2017 Colour Multimedia Enterprises, and contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

package twinspire;

import kha.Assets;
import kha.Image;
import kha.Font;
import kha.Blob;
import kha.Video;
import kha.Sound;

/**
* The `ResourceManager` divides resources into groups, so that you only load resources as and when
* they are required. When creating an `Application`, a `ResourceManager` is automatically created.
* If you have a resource named `Manager.txt`, this is resembled as a `Blob` in the name `Manager_txt`.
* The Application will automatically detect this, and perform group management of the resources you
* include.
*
* You can still load specific resources using `Kha.Assets` if you prefer.
**/
class ResourceManager
{

	private var _groups:ResourceGroup;



	public var images:Array<Image>;
	public var fonts:Array<Font>;
	public var misc:Array<Blob>;
	public var sounds:Array<Sound>;
	public var videos:Array<Video>;

	/**
	* Initialise a new `ResourceManager`.
	**/
	public function new()
	{
		_groups = new ResourceGroup();

		images = [];
		fonts = [];
		misc = [];
		sounds = [];
		videos = [];
	}

	/**
	* Create a resource group containing the names of resources with their associated type.
	*
	* @param names			The name of the group.
	* @param resources		The resources names associated with this group.
	**/
	public function createGroup(name:String, resources:Array<Resource>):Void
	{
		if (_groups.exists(name))
		{
			trace("A group with the name '" + name + "' already exists.");
			return;
		}

		_groups.set(name, resources);
	}

	/**
	* Loads a resource by the given `name` from `Assets.blobs` and returns the integer value
	* of the location in the local cache.
	* 
	* @param name		The name of the asset you want to load.
	*
	* @return Returns the zero-based integer value indicating the location of the loaded resource.
	**/
	public function loadMisc(name:String):Int
	{
		var file:Blob = Reflect.field(Assets.blobs, name);
		if (file == null)
			return -1;

		for (i in 0...misc.length)
		{
			var m = misc[i];
			if (file == m)
				return i;
		}

		misc.push(file);
		return misc.length - 1;
	}

	/**
	* Loads a resource by the given `name` from `Assets.fonts` and returns the integer value
	* of the location in the local cache.
	* 
	* @param name		The name of the asset you want to load.
	*
	* @return Returns the zero-based integer value indicating the location of the loaded resource.
	**/
	public function loadFont(name:String):Int
	{
		var file:Font = Reflect.field(Assets.fonts, name);
		if (file == null)
			return -1;

		for (i in 0...fonts.length)
		{
			var f = fonts[i];
			if (file == f)
				return i;
		}

		fonts.push(file);
		return fonts.length - 1;
	}

	/**
	* Loads a resource by the given `name` from `Assets.sounds` and returns the integer value
	* of the location in the local cache.
	* 
	* @param name		The name of the asset you want to load.
	*
	* @return Returns the zero-based integer value indicating the location of the loaded resource.
	**/
	public function loadSound(name:String):Int
	{
		var file:Sound = Reflect.field(Assets.sounds, name);
		if (file == null)
			return -1;

		for (i in 0...sounds.length)
		{
			var s = sounds[i];
			if (file == s)
				return i;
		}

		sounds.push(file);
		return sounds.length - 1;
	}

	/**
	* Loads a resource by the given `name` from `Assets.images` and returns the integer value
	* of the location in the local cache.
	* 
	* @param name		The name of the asset you want to load.
	*
	* @return Returns the zero-based integer value indicating the location of the loaded resource.
	**/
	public function loadImage(name:String):Int
	{
		var file:Image = Reflect.field(Assets.images, name);
		if (file == null)
			return -1;

		for (i in 0...images.length)
		{
			var img = images[i];
			if (file == img)
				return i;
		}

		images.push(file);
		return images.length - 1;
	}

	/**
	* Loads a resource by the given `name` from `Assets.videos` and returns the integer value
	* of the location in the local cache.
	* 
	* @param name		The name of the asset you want to load.
	*
	* @return Returns the zero-based integer value indicating the location of the loaded resource.
	**/
	public function loadVideo(name:String):Int
	{
		var file:Video = Reflect.field(Assets.videos, name);
		if (file == null)
			return -1;

		for (i in 0...videos.length)
		{
			var v = videos[i];
			if (file == v)
				return i;
		}

		videos.push(file);
		return videos.length - 1;
	}

}