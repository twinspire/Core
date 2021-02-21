package twinspire;

import kha.Assets;
import kha.Image;
import kha.Font;
import kha.Blob;
import kha.Video;
import kha.Sound;

import twinspire.ResourceType;

using StringTools;

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

	public function loadGroup(group:String)
	{
		if (_groups.exists(group))
		{
			var resources = _groups.get(group);
			for (res in resources)
			{
				switch (res.type)
				{
					case RESOURCE_ART:
						loadImage(res.name);
					case RESOURCE_FONT:
						loadFont(res.name);
					case RESOURCE_SOUND:
						loadSound(res.name);
					case RESOURCE_MISC:
						loadMisc(res.name);
					case RESOURCE_VIDEO:
						loadVideo(res.name);
				}
			}
		}
	}


	public function setup(file:String):Void
	{
		var data:Blob = Reflect.field(Assets.blobs, file);
		if (data == null)
			return;
		
		var contents = data.readUtf8String();
		var lines = contents.split("\n");

		var resources = new Array<Resource>();
		var group = "";

		for (i in 0...lines.length)
		{
			var line = lines[i];
			if (line == "\r")
				continue;
			
			if (line.endsWith("\r"))
				line = line.substring(0, line.length - 1);

			if (line.startsWith("Group"))
			{
				if (resources.length > 0)
				{
					createGroup(group, resources);
					resources = [];
				}

				var len = "Group".length;
				var groupName = line.substr(len + 1, line.length - len - 1);
				group = groupName;
			}
			else
			{
				if (line == "")
					continue;
				
				var space_index = line.indexOf(" ");
				var type = line.substr(0, space_index);
				if (checkResourceTypeName(type))
				{
					var resource_name = line.substr(space_index + 1, line.length - space_index + 1);
					if (resource_name.indexOf("*") > -1)
					{
						var index = resource_name.indexOf("*");
						var left = resource_name.substr(0, index);
						var right = resource_name.substr(index + 1, resource_name.length - index + 1);
						for (res in includeResources(type, left, right))
						{
							resources.push(res);
						}
					}
					else
					{
						resources.push(includeResource(type, resource_name));
					}
				}
			}

			if (i + 1 == lines.length)
			{
				createGroup(group, resources);
				break;
			}
		}
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


	/**
	* Private functions
	**/

	private function includeResource(type:String, name:String):Resource
	{
		var res = new Resource();
		var _type = 0;
		if (type == "font")
			_type = RESOURCE_FONT;
		else if (type == "blob")
			_type = RESOURCE_MISC;
		else if (type == "video")
			_type = RESOURCE_VIDEO;
		else if (type == "sound")
			_type = RESOURCE_SOUND;
		else if (type == "image")
			_type = RESOURCE_ART;
		
		res.type = _type;
		res.name = name;
		return res;
	}

	private function includeResources(type:String, left:String, right:String):Array<Resource>
	{
		var _type = 0;
		if (type == "font")
			_type = RESOURCE_FONT;
		else if (type == "blob")
			_type = RESOURCE_MISC;
		else if (type == "video")
			_type = RESOURCE_VIDEO;
		else if (type == "sound")
			_type = RESOURCE_SOUND;
		else if (type == "image")
			_type = RESOURCE_ART;
		
		var resources = new Array<Resource>();
		
		switch (_type)
		{
			case RESOURCE_FONT:
				for (field in Reflect.fields(Assets.fonts))
				{
					if (field.endsWith("Load") || field.endsWith("Description") || field.endsWith("Name") || field.endsWith("Unload") || field == "names")
						continue;
					
					if (field.indexOf(left) > -1)
					{
						if (right != "" && field.indexOf(right) > -1)
						{
							var res = new Resource();
							res.name = field;
							res.type = _type;
							resources.push(res);
						}
						else if (right == "")
						{
							var res = new Resource();
							res.name = field;
							res.type = _type;
							resources.push(res);
						}
					}
				}
			case RESOURCE_ART:
				for (field in Reflect.fields(Assets.images))
				{
					if (field.endsWith("Load") || field.endsWith("Description") || field.endsWith("Name") || field.endsWith("Unload") || field == "names")
						continue;
					
					if (field.indexOf(left) > -1)
					{
						if (right != "" && field.indexOf(right) > -1)
						{
							var res = new Resource();
							res.name = field;
							res.type = _type;
							resources.push(res);
						}
						else if (right == "")
						{
							var res = new Resource();
							res.name = field;
							res.type = _type;
							resources.push(res);
						}
					}
				}
			case RESOURCE_MISC:
				for (field in Reflect.fields(Assets.blobs))
				{
					if (field.endsWith("Load") || field.endsWith("Description") || field.endsWith("Name") || field.endsWith("Unload") || field == "names")
						continue;
					
					if (field.indexOf(left) > -1)
					{
						if (right != "" && field.indexOf(right) > -1)
						{
							var res = new Resource();
							res.name = field;
							res.type = _type;
							resources.push(res);
						}
						else if (right == "")
						{
							var res = new Resource();
							res.name = field;
							res.type = _type;
							resources.push(res);
						}
					}
				}
			case RESOURCE_SOUND:
				for (field in Reflect.fields(Assets.sounds))
				{
					if (field.endsWith("Load") || field.endsWith("Description") || field.endsWith("Name") || field.endsWith("Unload") || field == "names")
						continue;
					
					if (field.indexOf(left) > -1)
					{
						if (right != "" && field.indexOf(right) > -1)
						{
							var res = new Resource();
							res.name = field;
							res.type = _type;
							resources.push(res);
						}
						else if (right == "")
						{
							var res = new Resource();
							res.name = field;
							res.type = _type;
							resources.push(res);
						}
					}
				}
			case RESOURCE_VIDEO:
				for (field in Reflect.fields(Assets.videos))
				{
					if (field.endsWith("Load") || field.endsWith("Description") || field.endsWith("Name") || field.endsWith("Unload") || field == "names")
						continue;
					
					if (field.indexOf(left) > -1)
					{
						if (right != "" && field.indexOf(right) > -1)
						{
							var res = new Resource();
							res.name = field;
							res.type = _type;
							resources.push(res);
						}
						else if (right == "")
						{
							var res = new Resource();
							res.name = field;
							res.type = _type;
							resources.push(res);
						}
					}
				}
		}

		return resources;
	}

	private function checkResourceTypeName(value:String):Bool
	{
		return (value == "font" || value == "blob" || value == "video" || value == "sound" || value == "image");
	}

}