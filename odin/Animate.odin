package main

ANIMATE_MAX :: 1000

Animate :: struct {
    animateTicks : [ANIMATE_MAX]f32,
    animateTicksDelays : [ANIMATE_MAX]f32,
    animateTickReset : [ANIMATE_MAX]bool,
    animateTickLoopDir : [ANIMATE_MAX]int,
    lastAnimateSecondsValue : f32,
    animateIndex : int,
    deltaTime : f32,
}

AnimateInit :: proc(anim : ^Animate) {
    AnimateClear(anim);
    anim.animateIndex = -1;
}

AnimateClear :: proc(using anim : ^Animate) {
    for i : int; i < ANIMATE_MAX; i += 1 {
        animateTicks[i] = 0.0;
        animateTickReset[i] = false;
        animateTickLoopDir[i] = 1;
        animateTicksDelays[i] = 0.0;
    }
}

AnimateTime :: proc(using anim : ^Animate, dt : f32) {
    deltaTime = dt;
}

AnimateCreateTick :: proc(using anim : ^Animate) -> int {
    animateIndex += 1;
    return animateIndex;
}

AnimateResetTicks :: proc(using anim : ^Animate) {
    for i : int; i < ANIMATE_MAX; i +=1 {
        if (animateTickReset[i]) {
            animateTicks[i] = 0.0;
            animateTickReset[i] = false;
        }
    }
}

AnimateTick :: proc(using anim : ^Animate, index : int, seconds : f32, delay : f32 = 0.0) -> bool {
    result := false;
    lastAnimateSecondsValue = seconds;

    if (delay > 0.0)
    {
        if (animateTicks[index] + deltaTime > seconds)
        {
            result = true;
            if (animateTicksDelays[index] + deltaTime > delay)
            {
                result = false;
                animateTicksDelays[index] = 0.0;
                animateTickReset[index] = true;
            }
            else
            {
                animateTicksDelays[index] += deltaTime;
            }
        }
        else 
        {
            animateTicks[index] += deltaTime;
        }
    }
    else
    {
        if (animateTicks[index] + deltaTime > seconds)
        {
            result = true;
        }
        else 
        {
            animateTicks[index] += deltaTime;
        }
    }

    return result;
}

AnimateTickCond :: proc(using anim : ^Animate, index : int, seconds : f32, conditional : bool) -> bool {
    if (conditional)
    {
        return AnimateTick(anim, index, seconds);
    }
    else
    {
        return false;
    }
}

AnimateTickLoop :: proc(using anim : ^Animate, index : int, seconds : f32, delay : f32 = 0.0) -> bool {
    result := false;
    lastAnimateSecondsValue = seconds;

    if (animateTickLoopDir[index] == 1)
    {
        if (animateTicks[index] + deltaTime > seconds)
        {
            result = true;
            animateTickLoopDir[index] = -1;
        }
        else 
        {
            animateTicks[index] += deltaTime;
        }
    }
    else if (animateTickLoopDir[index] == -1)
    {
        if (animateTicksDelays[index] + deltaTime > delay)
        {
            if (animateTicks[index] - deltaTime < 0)
            {
                result = true;
                animateTickLoopDir[index] = 1;
            }
            else
            {
                animateTicks[index] -= deltaTime;
            }

            animateTicksDelays[index] = 0.0;
        }
        else 
        {
            animateTicksDelays[index] += deltaTime;
        }
    }

    return result;
}

AnimateGetRatio :: proc(using anim : ^Animate, index : int) -> f32 {
    return animateTicks[index] / lastAnimateSecondsValue;
}

AnimateReset :: proc(using anim : ^Animate, index : int) {
    animateTickReset[index] = true;
}