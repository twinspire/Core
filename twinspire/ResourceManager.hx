package twinspire;

import kha.Assets;
import kha.Image;
import kha.Font;
import kha.Blob;
import kha.Video;
import kha.Sound;

import twinspire.ResourceType;
import twinspire.ResourceGroup;

using StringTools;

/**
* The `ResourceManager` as a convenience class for managing resources as and
* when needed. This should be used over directly managing resources with `Kha.Assets`
* for more efficient memory handling, and only loads resources into memory
* when they are required.
*
* You can still load specific resources using `Kha.Assets` if you prefer.
**/
class ResourceManager
{

	private var imageMap:Map<String, Int>;
	private var fontMap:Map<String, Int>;
	private var soundMap:Map<String, Int>;
	private var videoMap:Map<String, Int>;
	private var blobMap:Map<String, Int>;

	private var loadedImages:Array<Image>;
	private var loadedFonts:Array<Font>;
	private var loadedSounds:Array<Sound>;
	private var loadedVideos:Array<Video>;
	private var loadedBlobs:Array<Blob>;

	private var requestLoadImages:Array<String>;
	private var requestLoadFonts:Array<String>;
	private var requestLoadSounds:Array<String>;
	private var requestLoadVideos:Array<String>;
	private var requestLoadBlobs:Array<String>;

	private var assetLoadCount:Int;
	private var assetsLoaded:Int;

	public var onError:(String) -> Void;

	public function new()
	{
		imageMap = new Map<String, Int>();
		fontMap = new Map<String, Int>();
		soundMap = new Map<String, Int>();
		videoMap = new Map<String, Int>();
		blobMap = new Map<String, Int>();

		requestLoadImages = [];
		requestLoadFonts = [];
		requestLoadSounds = [];
		requestLoadVideos = [];
		requestLoadBlobs = [];

		loadedBlobs = [];
		loadedFonts = [];
		loadedImages = [];
		loadedSounds = [];
		loadedVideos = [];
	}

	/**
	 * Clear all sounds currently loaded in memory.
	 */
	public function clearAllSounds()
	{
		for (loaded in loadedSounds)
		{
			loaded.unload();
		}

		loadedSounds = [];
		for (k => v in soundMap)
		{
			soundMap.remove(k);	
		}
	}

	/**
	 * Remove from memory the sound of the specified name.
	 * @param name The Kha-generated name of the specific sound to remove.
	 */
	public function clearSound(name:String)
	{
		if (soundMap.exists(name))
		{
			var index = soundMap.get(name);
			loadedSounds[index].unload();
			loadedSounds.splice(index, 1);
			soundMap.remove(name);
		}
	}

	/**
	 * Clear all fonts currently loaded in memory.
	 */
	public function clearAllFonts()
	{
		for (loaded in loadedFonts)
		{
			loaded.unload();
		}

		loadedFonts = [];
		for (k => v in fontMap)
		{
			fontMap.remove(k);	
		}
	}

	/**
	 * Remove from memory the font of the specified name.
	 * @param name The Kha-generated name of the specific font to remove.
	 */
	public function clearFont(name:String)
	{
		if (fontMap.exists(name))
		{
			var index = fontMap.get(name);
			loadedFonts[index].unload();
			loadedFonts.splice(index, 1);
			fontMap.remove(name);
		}
	}

	/**
	 * Clear all images currently loaded in memory.
	 */
	public function clearAllImages()
	{
		for (loaded in loadedImages)
		{
			loaded.unload();
		}

		loadedImages = [];
		for (k => v in imageMap)
		{
			imageMap.remove(k);	
		}
	}

	/**
	 * Remove from memory the image of the specified name.
	 * @param name The Kha-generated name of the specific image to remove.
	 */
	public function clearImage(name:String)
	{
		if (imageMap.exists(name))
		{
			var index = imageMap.get(name);
			loadedImages[index].unload();
			loadedImages.splice(index, 1);
			imageMap.remove(name);
		}
	}

	/**
	 * Clear all blobs currently loaded in memory.
	 */
	public function clearAllBlobs()
	{
		for (loaded in loadedBlobs)
		{
			loaded.unload();
		}

		loadedBlobs = [];
		for (k => v in blobMap)
		{
			blobMap.remove(k);	
		}
	}

	/**
	 * Remove from memory the blob of the specified name.
	 * @param name The Kha-generated name of the specific blob to remove.
	 */
	public function clearBlob(name:String)
	{
		if (blobMap.exists(name))
		{
			var index = blobMap.get(name);
			loadedBlobs[index].unload();
			loadedBlobs.splice(index, 1);
			blobMap.remove(name);
		}
	}

	/**
	 * Clear all videos currently loaded in memory.
	 */
	public function clearAllVideos()
	{
		for (loaded in loadedVideos)
		{
			loaded.unload();
		}

		loadedVideos = [];
		for (k => v in videoMap)
		{
			videoMap.remove(k);	
		}
	}

	/**
	 * Remove from memory the video of the specified name.
	 * @param name The Kha-generated name of the specific video to remove.
	 */
	public function clearVideo(name:String)
	{
		if (videoMap.exists(name))
		{
			var index = videoMap.get(name);
			loadedVideos[index].unload();
			loadedVideos.splice(index, 1);
			videoMap.remove(name);
		}
	}

	/**
	 * Clear all the resources from memory within this group.
	 * Naming rules, including wildcards, will apply when clearing resources.
	 * @param group The group of resources to clear.
	 */
	public function clearGroup(group:ResourceGroup)
	{
		if (group.blobs != null && group.blobs.length > 0)
		{
			for (name in group.blobs)
			{
				var assets = findAssets(name, RESOURCE_MISC);
				for (a in assets)
					clearBlob(a);
			}
		}

		if (group.fonts != null && group.fonts.length > 0)
		{
			for (name in group.fonts)
			{
				var assets = findAssets(name, RESOURCE_FONT);
				for (a in assets)
					clearFont(a);
			}
		}

		if (group.images != null && group.images.length > 0)
		{
			for (name in group.images)
			{
				var assets = findAssets(name, RESOURCE_ART);
				for (a in assets)
					clearImage(a);
			}
		}

		if (group.sounds != null && group.sounds.length > 0)
		{
			for (name in group.sounds)
			{
				var assets = findAssets(name, RESOURCE_SOUND);
				for (a in assets)
					clearSound(a);
			}
		}

		if (group.videos != null && group.videos.length > 0)
		{
			for (name in group.videos)
			{
				var assets = findAssets(name, RESOURCE_VIDEO);
				for (a in assets)
					clearVideo(a);
			}
		}
	}

	/**
	 * Retrieve a font by their respective kha-generated name.
	 * @param name The provided kha-generated name.
	 * @return Font 
	 */
	public function getFont(name:String):Font
	{
		if (fontMap.exists(name))
		{
			return loadedFonts[fontMap.get(name)];
		}

		if (onError != null)
		{
			onError('Font by the name $name was not loaded or found.');
		}

		return null;
	}

	/**
	 * Retrieve an image by their respective kha-generated name.
	 * @param name The provided kha-generated name.
	 * @return Image 
	 */
	public function getImage(name:String):Image
	{
		if (imageMap.exists(name))
		{
			return loadedImages[imageMap.get(name)];
		}

		if (onError != null)
		{
			onError('Image by the name $name was not loaded or found.');
		}

		return null;
	}

	/**
	 * Retrieve a Sound by their respective kha-generated name.
	 * @param name The provided kha-generated name.
	 * @return Sound 
	 */
	public function getSound(name:String):Sound
	{
		if (soundMap.exists(name))
		{
			return loadedSounds[soundMap.get(name)];
		}

		if (onError != null)
		{
			onError('Sound by the name $name was not loaded or found.');
		}

		return null;
	}

	/**
	 * Retrieve a Video by their respective kha-generated name.
	 * @param name The provided kha-generated name.
	 * @return Video 
	 */
	public function getVideo(name:String):Video
	{
		if (videoMap.exists(name))
		{
			return loadedVideos[videoMap.get(name)];
		}

		if (onError != null)
		{
			onError('Video by the name $name was not loaded or found.');
		}

		return null;
	}

	/**
	 * Retrieve a Blob by their respective kha-generated name.
	 * @param name The provided kha-generated name.
	 * @return Blob 
	 */
	public function getBlob(name:String):Blob
	{
		if (blobMap.exists(name))
		{
			return loadedBlobs[blobMap.get(name)];
		}

		if (onError != null)
		{
			onError('Blob by the name $name was not loaded or found.');
		}

		return null;
	}

	/**
	* Perform a request to load images by providing a list of their respective names
	* generated by Kha. You can use the wildcard (*) to perform searches on Asset names to
	* acquire more than one image providing they match the beginning, end, or both,
	* of the given name.
	*/
	public function loadImages(names:Array<String>)
	{
		assetsLoaded = 0;
		requestLoadImages = [];
		for (i in 0...names.length)
		{
			var asset:String = names[i];
			var foundAssets:Array<String> = findAssets(asset, RESOURCE_ART);
			var count:Int = 0;
			for (found in foundAssets)
			{
				var exists = false;
				for (k => v in imageMap)
				{
					if (found == k)
					{
						exists = true;
						break;
					}
				}

				if (!exists)
				{
					requestLoadImages.push(found);
					count++;
				}
			}
			
			assetLoadCount += count;
		}
	}

	/**
	* Perform a request to load fonts by providing a list of their respective names
	* generated by Kha. You can use the wildcard (*) to perform searches on Asset names to
	* acquire more than one font providing they match the beginning, end, or both,
	* of the given name.
	*/
	public function loadFonts(names:Array<String>)
	{
		assetsLoaded = 0;
		requestLoadFonts = [];
		for (i in 0...names.length)
		{
			var asset:String = names[i];
			var foundAssets:Array<String> = findAssets(asset, RESOURCE_FONT);
			var count:Int = 0;
			for (found in foundAssets)
			{
				var exists = false;
				for (k => v in fontMap)
				{
					if (found == k)
					{
						exists = true;
						break;
					}
				}

				if (!exists)
				{
					requestLoadFonts.push(found);
					count++;
				}
			}
			
			assetLoadCount += count;
		}
	}

	/**
	* Perform a request to load sounds by providing a list of their respective names
	* generated by Kha. You can use the wildcard (*) to perform searches on Asset names to
	* acquire more than one sound providing they match the beginning, end, or both,
	* of the given name.
	* 
	* NOTE: Some sound files may be large. It is important to only load sounds when they are
	* required to minimise memory consumption.
	*/
	public function loadSounds(names:Array<String>)
	{
		assetsLoaded = 0;
		requestLoadSounds = [];
		for (i in 0...names.length)
		{
			var asset:String = names[i];
			var foundAssets:Array<String> = findAssets(asset, RESOURCE_SOUND);
			var count:Int = 0;
			for (found in foundAssets)
			{
				var exists = false;
				for (k => v in soundMap)
				{
					if (found == k)
					{
						exists = true;
						break;
					}
				}

				if (!exists)
				{
					requestLoadSounds.push(found);
					count++;
				}
			}
			
			assetLoadCount += count;
		}
	}

	/**
	* Perform a request to load videos by providing a list of their respective names
	* generated by Kha. You can use the wildcard (*) to perform searches on Asset names to
	* acquire more than one video providing they match the beginning, end, or both,
	* of the given name.
	* 
	* NOTE: Some video files may be large. It is important to only load videos when they are
	* required to minimise memory consumption.
	*/
	public function loadVideos(names:Array<String>)
	{
		assetsLoaded = 0;
		requestLoadVideos = [];
		for (i in 0...names.length)
		{
			var asset:String = names[i];
			var foundAssets:Array<String> = findAssets(asset, RESOURCE_VIDEO);
			var count:Int = 0;
			for (found in foundAssets)
			{
				var exists = false;
				for (k => v in videoMap)
				{
					if (found == k)
					{
						exists = true;
						break;
					}
				}

				if (!exists)
				{
					requestLoadVideos.push(found);
					count++;
				}
			}
			
			assetLoadCount += count;
		}
	}

	/**
	* Perform a request to load blobs by providing a list of their respective names
	* generated by Kha. You can use the wildcard (*) to perform searches on Asset names to
	* acquire more than one blob providing they match the beginning, end, or both,
	* of the given name.
	*/
	public function loadBlobs(names:Array<String>)
	{
		assetsLoaded = 0;
		requestLoadBlobs = [];
		for (i in 0...names.length)
		{
			var asset:String = names[i];
			var foundAssets:Array<String> = findAssets(asset, RESOURCE_MISC);
			var count:Int = 0;
			for (found in foundAssets)
			{
				var exists = false;
				for (k => v in blobMap)
				{
					if (found == k)
					{
						exists = true;
						break;
					}
				}

				if (!exists)
				{
					requestLoadBlobs.push(found);
					count++;
				}
			}
			
			assetLoadCount += count;
		}
	}

	/**
	 * Loads a group of resources of varying types. Convenience method to organise resources.
	 * Naming rules apply in the same way as individual load functions.
	 * @param group The group of resources to load.
	 */
	public function loadGroup(group:ResourceGroup)
	{
		if (group.blobs != null && group.blobs.length > 0)
		{
			loadBlobs(group.blobs);
		}

		if (group.fonts != null && group.fonts.length > 0)
		{
			loadFonts(group.fonts);
		}

		if (group.images != null && group.images.length > 0)
		{
			loadImages(group.images);
		}

		if (group.sounds != null && group.sounds.length > 0)
		{
			loadSounds(group.sounds);
		}

		if (group.videos != null && group.videos.length > 0)
		{
			loadVideos(group.videos);
		}
	}

	private function findAssets(name:String, type:ResourceType):Array<String>
	{
		var array:Array<String> = [];
		if (type == RESOURCE_ART)
		{
			array = Assets.images.names;
		}
		else if (type == RESOURCE_FONT)
		{
			array = Assets.fonts.names;
		}
		else if (type == RESOURCE_SOUND)
		{
			array = Assets.sounds.names;
		}
		else if (type == RESOURCE_VIDEO)
		{
			array = Assets.videos.names;
		}
		else if (type == RESOURCE_MISC)
		{
			array = Assets.blobs.names;
		}

		var asterisk:Int = name.indexOf("*");
		var matchStart:Bool = false;
		var matchEnd:Bool = false;
		// match anything from left of name
		if (asterisk == 0)
		{
			matchStart = true;
		}
		// match anything from right of name
		var nextAsterisk:Int = name.indexOf("*", asterisk + 1);
		if ((nextAsterisk > 0 && nextAsterisk != asterisk + 1) || asterisk == name.length - 1)
		{
			matchEnd = true;
		}

		var results:Array<String> = [];

		for (i in 0...array.length)
		{
			var item:String = array[i];
			if (!matchStart && !matchEnd && item == name)
			{
				results.push(item);
			}
			else
			{
				if (matchStart && !matchEnd && item.endsWith(name.substr(asterisk + 1)))
				{
					results.push(item);
				}
				else if (!matchStart && matchEnd && item.startsWith(name.substr(0, nextAsterisk)))
				{
					results.push(item);				
				}
				else if (matchStart && matchEnd && item.indexOf(name) > -1)
				{
					results.push(item);
				}
			}
		}

		return results;
	}

	/**
	 * Submit the load request, loading in all requested Assets into memory and generating name -> index
	 * mapping for the loaded resources for easy access.
	 * 
	 * @param complete The callback function to execute when this operation completes.
	 * @param progress The callback function to execute when progress has been performed.
	 */
	public function submitLoadRequest(complete:() -> Void, ?progress:(Int, Int) -> Void)
	{
		// font loading
		for (i in 0...requestLoadFonts.length)
		{
			var request:String = requestLoadFonts[i];
			Assets.loadFont(request, (f:Font) -> 
			{ 
				loadedFonts.push(f);
				fontMap.set(request, loadedFonts.length - 1);
				assetsLoaded++;
				if (progress != null)
					progress(assetsLoaded, assetLoadCount);
				
				if (assetsLoaded == assetLoadCount)
				{
					clearRequests();
					complete();
				}
			});
		}

		// image loading
		for (i in 0...requestLoadImages.length)
		{
			var request:String = requestLoadImages[i];
			Assets.loadImage(request, (f:Image) -> 
			{
				loadedImages.push(f);
				imageMap.set(request, loadedImages.length - 1);
				assetsLoaded++;
				if (progress != null)
					progress(assetsLoaded, assetLoadCount);
				
				if (assetsLoaded == assetLoadCount)
				{
					clearRequests();
					complete();
				}
			});
		}

		// sound loading
		for (i in 0...requestLoadSounds.length)
		{
			var request:String = requestLoadSounds[i];
			Assets.loadSound(request, (f:Sound) -> 
			{
				f.uncompress(() -> {
					loadedSounds.push(f);
					soundMap.set(request, loadedSounds.length - 1);
					assetsLoaded++;
					if (progress != null)
						progress(assetsLoaded, assetLoadCount);
					
					if (assetsLoaded == assetLoadCount)
					{
						clearRequests();
						complete();
					}
				});
			}, (e) -> {
				trace(e.error);
			});
		}

		// video loading
		for (i in 0...requestLoadVideos.length)
		{
			var request:String = requestLoadVideos[i];
			Assets.loadVideo(request, (f:Video) -> 
			{
				loadedVideos.push(f);
				videoMap.set(request, loadedVideos.length - 1);
				assetsLoaded++;
				if (progress != null)
					progress(assetsLoaded, assetLoadCount);
				
				if (assetsLoaded == assetLoadCount)
				{
					clearRequests();
					complete();
				}
			});
		}

		// blob loading
		for (i in 0...requestLoadBlobs.length)
		{
			var request:String = requestLoadBlobs[i];
			Assets.loadBlob(request, (f:Blob) -> 
			{
				loadedBlobs.push(f);
				blobMap.set(request, loadedBlobs.length - 1);
				assetsLoaded++;
				if (progress != null)
					progress(assetsLoaded, assetLoadCount);
				
				if (assetsLoaded == assetLoadCount)
				{
					clearRequests();
					complete();
				}
			});
		}
	}

	private function clearRequests()
	{
		assetLoadCount = 0;
		requestLoadBlobs = [];
		requestLoadFonts = [];
		requestLoadImages = [];
		requestLoadSounds = [];
		requestLoadVideos = [];
	}

}