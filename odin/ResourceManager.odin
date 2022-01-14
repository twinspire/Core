package main

import c "core:c/libc"
import "core:strings"
import "core:fmt"
import rl "vendor:raylib"

Resource :: struct {
    name : string,
    path : string,
}

ResourceManager :: struct {
    textureMap : map[string]int,
    fontMap : map[string]int,
    soundMap : map[string]int,
    musicMap : map[string]int,
    blobMap : map[string]int,

    loadedTextures : [dynamic]rl.Texture2D,
    loadedFonts : [dynamic]rl.Font,
    loadedSounds : [dynamic]rl.Sound,
    loadedMusic : [dynamic]rl.Music,
    loadedBlobs : [dynamic]string,

    requestLoadTextures : [dynamic]Resource,
    requestLoadFonts : [dynamic]Resource,
    requestLoadSounds : [dynamic]Resource,
    requestLoadMusic : [dynamic]Resource,
    requestLoadBlobs : [dynamic]Resource,

    assetLoadCount : int,
    assetsLoaded : int,

    textures : [dynamic]Resource,
    fonts : [dynamic]Resource,
    sounds : [dynamic]Resource,
    music : [dynamic]Resource,
    blobs : [dynamic]Resource,
}

ResourceGroup :: struct {
    fonts : []string,
    textures : []string,
    sounds : []string,
    music : []string,
    blobs : []string,
}

ResourceType :: enum {
    FONT,
    TEXTURE,
    SOUND,
    MUSIC,
    BLOB,
}

ResourceDirectories :: struct {
    fontPaths : []string,
    texturePaths : []string,
    soundPaths : []string,
    musicPaths : []string,
    blobPaths : []string,
}

Resources_Create :: proc(directories : ResourceDirectories) -> ResourceManager {
    using manager : ResourceManager = {};
    loadedTextures = make([dynamic]rl.Texture2D);
    loadedFonts = make([dynamic]rl.Font);
    loadedSounds = make([dynamic]rl.Sound);
    loadedMusic = make([dynamic]rl.Music);
    loadedBlobs = make([dynamic]string);

    requestLoadTextures = make([dynamic]Resource);
    requestLoadFonts = make([dynamic]Resource);
    requestLoadSounds = make([dynamic]Resource);
    requestLoadMusic = make([dynamic]Resource);
    requestLoadBlobs = make([dynamic]Resource);

    textures = make([dynamic]Resource);
    fonts = make([dynamic]Resource);
    sounds = make([dynamic]Resource);
    music = make([dynamic]Resource);
    blobs = make([dynamic]Resource);

    fontMap = map[string]int{};
    textureMap = map[string]int{};
    soundMap = map[string]int{};
    musicMap = map[string]int{};
    blobMap = map[string]int{};

    // detect files of specific types
    for path in directories.fontPaths {
        count : c.int;
        cpath := strings.clone_to_cstring(path);
        files := rl.GetDirectoryFiles(cpath, &count);
        total : int = cast(int)count;
        for i : int; i < total; i += 1 {
            if (rl.IsFileExtension(files[i], ".ttf") ||
                rl.IsFileExtension(files[i], ".otf")) {
                fontRes := Resource{};
                fileStr := strings.clone_from_cstring(files[i]);
                fontRes.name = strings.clone_from_cstring(rl.GetFileNameWithoutExt(files[i]));
                fontRes.path = strings.concatenate([]string { path, fileStr });
                append(&fonts, fontRes);
            }
        }
    }

    for path in directories.texturePaths {
        count : c.int;
        cpath := strings.clone_to_cstring(path);
        files := rl.GetDirectoryFiles(cpath, &count);
        total : int = cast(int)count;
        for i : int; i < total; i += 1 {
            if (rl.IsFileExtension(files[i], ".png")) {
                imageRes := Resource{};
                fileStr := strings.clone_from_cstring(files[i]);
                imageRes.name = strings.clone_from_cstring(rl.GetFileNameWithoutExt(files[i]));
                imageRes.path = strings.concatenate([]string { path, fileStr });
                append(&textures, imageRes);
            }
        }
    }

    for path in directories.soundPaths {
        count : c.int;
        cpath := strings.clone_to_cstring(path);
        files := rl.GetDirectoryFiles(cpath, &count);
        total : int = cast(int)count;
        for i : int; i < total; i += 1 {
            if (rl.IsFileExtension(files[i], ".wav") ||
                rl.IsFileExtension(files[i], ".ogg")) {
                soundRes := Resource{};
                fileStr := strings.clone_from_cstring(files[i]);
                soundRes.name = strings.clone_from_cstring(rl.GetFileNameWithoutExt(files[i]));
                soundRes.path = strings.concatenate([]string { path, fileStr });
                append(&sounds, soundRes);
            }
        }
    }

    for path in directories.musicPaths {
        count : c.int;
        cpath := strings.clone_to_cstring(path);
        files := rl.GetDirectoryFiles(cpath, &count);
        total : int = cast(int)count;
        for i : int; i < total; i += 1 {
            if (rl.IsFileExtension(files[i], ".wav") ||
                rl.IsFileExtension(files[i], ".ogg") ||
                rl.IsFileExtension(files[i], ".mp3")) {
                musicRes := Resource{};
                fileStr := strings.clone_from_cstring(files[i]);
                musicRes.name = strings.clone_from_cstring(rl.GetFileNameWithoutExt(files[i]));
                musicRes.path = strings.concatenate([]string { path, fileStr });
                append(&music, musicRes);
            }
        }
    }

    for path in directories.blobPaths {
        count : c.int;
        cpath := strings.clone_to_cstring(path);
        files := rl.GetDirectoryFiles(cpath, &count);
        total : int = cast(int)count;
        for i : int; i < total; i += 1 {
            blobRes := Resource{};
            fileStr := strings.clone_from_cstring(files[i]);
            blobRes.name = strings.clone_from_cstring(rl.GetFileNameWithoutExt(files[i]));
            blobRes.path = strings.concatenate([]string { path, fileStr });
            append(&blobs, blobRes);
        }
    }

    return manager;
}

Resources_ClearAll :: proc(using manager : ^ResourceManager) {
    Resources_ClearAllSounds(manager);
    Resources_ClearAllFonts(manager);
    Resources_ClearAllTextures(manager);
    Resources_ClearAllMusic(manager);
}

Resources_ClearAllSounds :: proc(using manager : ^ResourceManager) {
    for loaded in loadedSounds {
        rl.UnloadSound(loaded);
    }

    loadedSounds = {};
    for k, _ in soundMap {
        delete_key(&soundMap, k);
    }
}

Resources_ClearSound :: proc(using manager : ^ResourceManager, name : string) {
    elem, ok := soundMap[name];
    if (ok) {
        rl.UnloadSound(loadedSounds[elem]);
        ordered_remove(&loadedSounds, elem);
        delete_key(&soundMap, name);
    }
}

Resources_ClearAllFonts :: proc(using manager : ^ResourceManager) {
    for loaded in loadedFonts {
        rl.UnloadFont(loaded);
    }

    loadedFonts = {};
    for k, _ in fontMap {
        delete_key(&fontMap, k);
    }
}

Resources_ClearFont :: proc(using manager : ^ResourceManager, name : string) {
    elem, ok := fontMap[name];
    if (ok) {
        rl.UnloadFont(loadedFonts[elem]);
        ordered_remove(&loadedFonts, elem);
        delete_key(&fontMap, name);
    }
}

Resources_ClearAllTextures :: proc(using manager : ^ResourceManager) {
    for loaded in loadedTextures {
        rl.UnloadTexture(loaded);
    }

    loadedTextures = {};
    for k, _ in textureMap {
        delete_key(&textureMap, k);
    }
}

Resources_ClearTexture :: proc(using manager : ^ResourceManager, name : string) {
    elem, ok := textureMap[name];
    if (ok) {
        rl.UnloadTexture(loadedTextures[elem]);
        ordered_remove(&loadedTextures, elem);
        delete_key(&textureMap, name);
    }
}

Resources_ClearAllMusic :: proc(using manager : ^ResourceManager) {
    for loaded in loadedMusic {
        rl.UnloadMusicStream(loaded);
    }

    loadedMusic = {};
    for k, _ in musicMap {
        delete_key(&musicMap, k);
    }
}

Resources_ClearMusic :: proc(using manager : ^ResourceManager, name : string) {
    elem, ok := musicMap[name];
    if (ok) {
        rl.UnloadMusicStream(loadedMusic[elem]);
        ordered_remove(&loadedMusic, elem);
        delete_key(&musicMap, name);
    }
}

Resources_ClearAllBlobs :: proc(using manager : ^ResourceManager) {
    loadedBlobs = {};
    for k, _ in blobMap {
        delete_key(&blobMap, k);
    }
}

Resources_ClearBlob :: proc(using manager : ^ResourceManager, name : string) {
    elem, ok := blobMap[name];
    if (ok) {
        ordered_remove(&loadedBlobs, elem);
        delete_key(&blobMap, name);
    }
}

Resources_ClearGroup :: proc(using manager : ^ResourceManager, group : ResourceGroup) {
    if (group.blobs != nil && len(group.blobs) > 0)
    {
        for name in group.blobs {
            assets := Resources_FindAssets(manager, name, ResourceType.BLOB);
            for a in assets {
                Resources_ClearBlob(manager, a.name);
            }
        }
    }

    if (group.fonts != nil && len(group.fonts) > 0)
    {
        for name in group.fonts {
            assets := Resources_FindAssets(manager, name, ResourceType.FONT);
            for a in assets {
                Resources_ClearFont(manager, a.name);
            }
        }
    }

    if (group.textures != nil && len(group.textures) > 0)
    {
        for name in group.textures {
            assets := Resources_FindAssets(manager, name, ResourceType.TEXTURE);
            for a in assets {
                Resources_ClearTexture(manager, a.name);
            }
        }
    }

    if (group.sounds != nil && len(group.sounds) > 0)
    {
        for name in group.sounds {
            assets := Resources_FindAssets(manager, name, ResourceType.SOUND);
            for a in assets {
                Resources_ClearSound(manager, a.name);
            }
        }
    }

    if (group.music != nil && len(group.music) > 0)
    {
        for name in group.music {
            assets := Resources_FindAssets(manager, name, ResourceType.MUSIC);
            for a in assets {
                Resources_ClearMusic(manager, a.name);
            }
        }
    }
}

Resources_GetFont :: proc(using manager : ^ResourceManager, name : string) -> ^rl.Font {
    elem, ok := fontMap[name];
    if ok {
        return &loadedFonts[elem];
    }

    return nil;
}

Resources_GetImage :: proc(using manager : ^ResourceManager, name : string) -> ^rl.Texture2D {
    elem, ok := textureMap[name];
    if ok {
        return &loadedTextures[elem];
    }

    return nil;
}

Resources_GetSound :: proc(using manager : ^ResourceManager, name : string) -> ^rl.Sound {
    elem, ok := soundMap[name];
    if ok {
        return &loadedSounds[elem];
    }

    return nil;
}

Resources_GetMusic :: proc(using manager : ^ResourceManager, name : string) -> ^rl.Music {
    elem, ok := musicMap[name];
    if ok {
        return &loadedMusic[elem];
    }

    return nil;
}

Resources_GetBlob :: proc(using manager : ^ResourceManager, name : string) -> ^string {
    elem, ok := blobMap[name];
    if ok {
        return &loadedBlobs[elem];
    }

    return nil;
}

Resources_LoadTextures :: proc(using manager : ^ResourceManager, names : []string) {
    assetsLoaded = 0;
    requestLoadTextures = make([dynamic]Resource);
    for i in 0..<len(names) {
        asset := names[i];
        foundAssets := Resources_FindAssets(manager, asset, ResourceType.TEXTURE);
        count := 0;
        for found in foundAssets {
            exists := false;
            for k, _ in textureMap {
                if found.name == k {
                    exists = true;
                    break;
                }
            }

            if !exists {
                append(&requestLoadTextures, found);
                count += 1;
            }
        }

        assetLoadCount += count;
    }
}

Resources_LoadFonts :: proc(using manager : ^ResourceManager, names : []string) {
    assetsLoaded = 0;
    requestLoadFonts = make([dynamic]Resource);
    for i in 0..<len(names) {
        asset := names[i];
        foundAssets := Resources_FindAssets(manager, asset, ResourceType.FONT);
        count := 0;
        for found in foundAssets {
            exists := false;
            for k, _ in fontMap {
                if found.name == k {
                    exists = true;
                    break;
                }
            }

            if !exists {
                append(&requestLoadFonts, found);
                count += 1;
            }
        }

        assetLoadCount += count;
    }
}

Resources_LoadSounds :: proc(using manager : ^ResourceManager, names : []string) {
    assetsLoaded = 0;
    requestLoadSounds = make([dynamic]Resource);
    for i in 0..<len(names) {
        asset := names[i];
        foundAssets := Resources_FindAssets(manager, asset, ResourceType.SOUND);
        count := 0;
        for found in foundAssets {
            exists := false;
            for k, _ in soundMap {
                if found.name == k {
                    exists = true;
                    break;
                }
            }

            if !exists {
                append(&requestLoadSounds, found);
                count += 1;
            }
        }

        assetLoadCount += count;
    }
}

Resources_LoadMusic :: proc(using manager : ^ResourceManager, names : []string) {
    assetsLoaded = 0;
    requestLoadMusic = make([dynamic]Resource);
    for i in 0..<len(names) {
        asset := names[i];
        foundAssets := Resources_FindAssets(manager, asset, ResourceType.MUSIC);
        count := 0;
        for found in foundAssets {
            exists := false;
            for k, _ in musicMap {
                if found.name == k {
                    exists = true;
                    break;
                }
            }

            if !exists {
                append(&requestLoadMusic, found);
                count += 1;
            }
        }

        assetLoadCount += count;
    }
}

Resources_LoadBlobs :: proc(using manager : ^ResourceManager, names : []string) {
    assetsLoaded = 0;
    requestLoadBlobs = make([dynamic]Resource);
    for i in 0..<len(names) {
        asset := names[i];
        foundAssets := Resources_FindAssets(manager, asset, ResourceType.BLOB);
        count := 0;
        for found in foundAssets {
            exists := false;
            for k, _ in blobMap {
                if found.name == k {
                    exists = true;
                    break;
                }
            }

            if !exists {
                append(&requestLoadBlobs, found);
                count += 1;
            }
        }

        assetLoadCount += count;
    }
}

Resources_LoadGroup :: proc(using manager : ^ResourceManager, group : ResourceGroup) {
    if group.blobs != nil && len(group.blobs) > 0 {
        Resources_LoadBlobs(manager, group.blobs);
    }

    if group.fonts != nil && len(group.fonts) > 0 {
        Resources_LoadFonts(manager, group.fonts);
    }

    if group.textures != nil && len(group.textures) > 0 {
        Resources_LoadTextures(manager, group.textures);
    }

    if group.sounds != nil && len(group.sounds) > 0 {
        Resources_LoadSounds(manager, group.sounds);
    }

    if group.music != nil && len(group.music) > 0 {
        Resources_LoadMusic(manager, group.music);
    }
}

Resources_FindAssets :: proc(using manager : ^ResourceManager, name : string, type : ResourceType) -> [dynamic]Resource {
    array : [dynamic]Resource;
    if (type == ResourceType.BLOB)
    {
        array = blobs;
    }
    else if (type == ResourceType.FONT)
    {
        array = fonts;
    }
    else if (type == ResourceType.SOUND)
    {
        array = sounds;
    }
    else if (type == ResourceType.MUSIC)
    {
        array = music;
    }
    else if (type == ResourceType.TEXTURE)
    {
        array = textures;
    }

    asterisk : int = strings.index_any(name, "*");
    matchStart : bool = false;
    matchEnd : bool = false;
    if asterisk == 0 {
        matchStart = true;
    }

    nextAsterisk : int = strings.index_any(name[asterisk + 1:], "*");
    if nextAsterisk == -1 && asterisk == len(name) - 1 {
        matchEnd = true;
        nextAsterisk = asterisk;
    }
    else if nextAsterisk > 0 && nextAsterisk != asterisk + 1 {
        matchEnd = true;
    }

    results := [dynamic]Resource{};
    for i in 0..<len(array) {
        item := array[i];
        if !matchStart && !matchEnd && item.name == name {
            append(&results, item);
        }
        else {
            if matchStart && !matchEnd {
                name_len := len(name[asterisk + 1:]);
                start := len(item.name) - name_len;

                if name[asterisk + 1:] == item.name[start:] {
                    append(&results, item);
                }
            }
            else if !matchStart && matchEnd && name[:nextAsterisk - 1] == item.name[:nextAsterisk - 1] {
                append(&results, item);
            }
            else if matchStart && matchEnd && strings.index_any(item.name, name[1:nextAsterisk - 1]) > -1 {
                append(&results, item);
            }
        }
    }

    return results;
}

Resources_SubmitLoadRequest :: proc(using manager : ^ResourceManager, onComplete : proc(^ResourceManager, int), onProgress : proc(^ResourceManager, int, int)) {
    if assetLoadCount == 0 && onComplete != nil {
        onComplete(manager, assetLoadCount);
        return;
    }

    for i in 0..<len(requestLoadFonts) {
        request := requestLoadFonts[i];
        load := rl.LoadFont(strings.clone_to_cstring(request.path));
        append(&loadedFonts, load);
        fontMap[request.name] = len(loadedFonts) - 1;
        assetsLoaded += 1;

        if onProgress != nil {
            onProgress(manager, assetsLoaded, assetLoadCount);
        }

        if assetsLoaded == assetLoadCount {
            Resources_ClearRequests(manager);
            onComplete(manager, assetsLoaded);
        }
    }

    for i in 0..<len(requestLoadTextures) {
        request := requestLoadTextures[i];
        load := rl.LoadTexture(strings.clone_to_cstring(request.path));
        append(&loadedTextures, load);
        textureMap[request.name] = len(loadedTextures) - 1;
        assetsLoaded += 1;

        if onProgress != nil {
            onProgress(manager, assetsLoaded, assetLoadCount);
        }

        if assetsLoaded == assetLoadCount {
            Resources_ClearRequests(manager);
            onComplete(manager, assetsLoaded);
        }
    }

    for i in 0..<len(requestLoadSounds) {
        request := requestLoadSounds[i];
        load := rl.LoadSound(strings.clone_to_cstring(request.path));
        append(&loadedSounds, load);
        soundMap[request.name] = len(loadedSounds) - 1;
        assetsLoaded += 1;

        if onProgress != nil {
            onProgress(manager, assetsLoaded, assetLoadCount);
        }

        if assetsLoaded == assetLoadCount {
            Resources_ClearRequests(manager);
            onComplete(manager, assetsLoaded);
        }
    }

    for i in 0..<len(requestLoadMusic) {
        request := requestLoadMusic[i];
        load := rl.LoadMusicStream(strings.clone_to_cstring(request.path));
        append(&loadedMusic, load);
        musicMap[request.name] = len(loadedMusic) - 1;
        assetsLoaded += 1;

        if onProgress != nil {
            onProgress(manager, assetsLoaded, assetLoadCount);
        }

        if assetsLoaded == assetLoadCount {
            Resources_ClearRequests(manager);
            onComplete(manager, assetsLoaded);
        }
    }

    for i in 0..<len(requestLoadBlobs) {
        request := requestLoadBlobs[i];
        data_length : c.uint;
        load := rl.LoadFileData(strings.clone_to_cstring(request.path), &data_length);
        strData := strings.string_from_nul_terminated_ptr(load, int(data_length));
        append(&loadedBlobs, strData);
        blobMap[request.name] = len(loadedBlobs) - 1;
        assetsLoaded += 1;

        if onProgress != nil {
            onProgress(manager, assetsLoaded, assetLoadCount);
        }

        if assetsLoaded == assetLoadCount {
            Resources_ClearRequests(manager);
            onComplete(manager, assetsLoaded);
        }
    }
}

Resources_ClearRequests :: proc(using manager : ^ResourceManager) {
    assetLoadCount = 0;
    requestLoadBlobs = {};
    requestLoadFonts = {};
    requestLoadMusic = {};
    requestLoadSounds = {};
    requestLoadTextures = {};
}