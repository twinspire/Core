package twinspire.render.particles;

import twinspire.extensions.Graphics2;

import kha.Image;
import kha.math.FastVector2;
import kha.Color;

enum ParticleShape {
    Circle;
    Square;
    Triangle;
    Image(img:Image);
}

enum EmissionType {
    /**
    * A continuous emission of particles at a fixed rate.
    * `numParticles` can be used to specify how many particles are emitted.
    * If `uniform` is true, particles will be spread uniformly.
    * If `curvature` is provided, particles will follow a curved path based on the curvature vector.
    **/
    Continuous(?numParticles:Int, ?uniform:Bool, ?curvature:FastVector2); // numParticles is optional, defaults to 10
    /**
    * Particles are emitted in bursts at regular intervals.
    * If `curvature` is provided, particles will follow a curved path based on the curvature vector.
    **/
    Burst(count:Int, interval:Float, ?curvature:FastVector2); // count is number of particles, interval is time between bursts
    /**
    * Particles are emitted in random bursts.
    * If `curvature` is provided, particles will follow a curved path based on the curvature vector.
    **/
    RandomBurst(minCount:Int, maxCount:Int, minInterval:Float, maxInterval:Float, ?curvature:FastVector2); // random count and interval
    /**
    * Sparks is "burst" except emits a continous stream of particles in a set direction using the given `count`.
    * Interval is determined by the `emissionRate` of the emitter.
    * `curvature` can be used to add a curve to the spark's path.
    **/
    Spark(count:Int, ?curvature:FastVector2);
}

private class BezierPath {
    public var startPoint:FastVector2;
    public var controlPoint1:FastVector2;
    public var controlPoint2:FastVector2;
    public var endPoint:FastVector2;
    
    public function new(start:FastVector2, cp1:FastVector2, cp2:FastVector2, end:FastVector2) {
        startPoint = new FastVector2(start.x, start.y);
        controlPoint1 = new FastVector2(cp1.x, cp1.y);
        controlPoint2 = new FastVector2(cp2.x, cp2.y);
        endPoint = new FastVector2(end.x, end.y);
    }
}

class Emitter {

    private var _bezierPaths:Array<BezierPath>;
    private var _pathProgress:Array<Float>;

    private var _particles:Array<FastVector2>;
    private var _velocities:Array<FastVector2>;
    private var _lifetimes:Array<Float>;
    private var _sizes:Array<Float>;
    private var _colors:Array<Color>;
    private var _activeParticles:Int = 0;
    
    /**
    * The position from which particles are emitted.
    **/
    public var position:FastVector2;
    /**
    * The direction of the emitted particles.
    **/
    public var velocity:FastVector2;
    /**
    * The rate at which particles are emitted (particles per second).
    **/
    public var emissionRate:Float;
    /**
    * The lifetime of each particle in seconds.
    **/
    public var particleLifetime:Float;
    /**
    * The size of each emitted particle.
    **/
    public var particleSize:Float;
    /**
    * Whether the particle size is variable or fixed.
    * When true, particles will vary in size using `particleSize` as a base size.
    **/
    public var variableSize:Bool;
    /**
    * Determines if the particle speed is variable or fixed.
    * When true, particles will vary in speed using `velocity` as a base speed.
    **/
    public var variableSpeed:Bool;
    /**
    * The color of the emitted particles.
    **/
    public var color:Color;
    /**
    * Causes particles to fade out over their lifetime.
    **/
    public var fadeOut:Bool;
    /**
    * The emission type determines how particles are emitted.
    **/
    public var emissionType:EmissionType;
    /**
    * The shape of the emitted particles.
    **/
    public var shape:ParticleShape;
    /**
    * How much particles should spread out from the original position when emitted.
    **/
    public var spread:Float;
    /**
    * The maximum number of particles that can be emitted at once.
    **/
    public var maxParticles:Int = 50;

    public function new(position:FastVector2, velocity:FastVector2, emissionRate:Float, particleLifetime:Float, particleSize:Float, color:kha.Color) {
        this.position = position;
        this.velocity = velocity;
        this.emissionRate = emissionRate;
        this.particleLifetime = particleLifetime;
        this.particleSize = particleSize;
        this.color = color;
        emissionType = Continuous(); // Default to continuous emission with 10 particles
        shape = Circle; // Default shape is Circle
        spread = 0.0;
    }

    public function update(deltaTime:Float):Void {
        // Initialize arrays if not already done
        if (_particles == null) {
            _particles = [];
            _velocities = [];
            _lifetimes = [];
            _sizes = [];
            _colors = [];
            _emissionAccumulator = 0.0;
            _burstTimer = 0.0;
            _nextBurstInterval = 0.0;
        }

        // Update existing particles
        updateExistingParticles(deltaTime);

        // Handle particle emission based on emission type
        switch (emissionType) {
            case Continuous(numParticles, uniform, curvature): {
                handleContinuousEmission(deltaTime, numParticles, uniform, curvature);
            }
            case Burst(count, interval, curvature): {
                handleBurstEmission(deltaTime, count, interval, curvature);
            }
            case RandomBurst(minCount, maxCount, minInterval, maxInterval, curvature): {
                handleRandomBurstEmission(deltaTime, minCount, maxCount, minInterval, maxInterval, curvature);
            }
            case Spark(count, curvature): {
                handleSparkEmission(deltaTime, count, curvature);
            }
        }
    }

    public function render(gtx:GraphicsContext):Void {
        if (_particles == null || _activeParticles == 0) {
            return;
        }

        var g2 = gtx.getCurrentGraphics();
        
        for (i in 0..._activeParticles) {
            if (i >= _particles.length) break;
            
            var particle = _particles[i];
            var particleColor = _colors[i];
            var particleSize = _sizes[i];
            
            // Set the color for rendering
            g2.color = particleColor;
            
            // Render based on particle shape
            switch (shape) {
                case Circle: {
                    Graphics2.fillCircle(g2, particle.x, particle.y, particleSize / 2);
                }
                case Square: {
                    g2.fillRect(particle.x - particleSize / 2, particle.y - particleSize / 2, particleSize, particleSize);
                }
                case Triangle: {
                    var halfSize = particleSize / 2;
                    var x1 = particle.x;
                    var y1 = particle.y - halfSize;
                    var x2 = particle.x - halfSize;
                    var y2 = particle.y + halfSize;
                    var x3 = particle.x + halfSize;
                    var y3 = particle.y + halfSize;
                    g2.fillTriangle(x1, y1, x2, y2, x3, y3);
                }
                case Image(img): {
                    if (img != null) {
                        g2.drawScaledImage(img, 
                            particle.x - particleSize / 2, 
                            particle.y - particleSize / 2, 
                            particleSize, particleSize);
                    }
                }
            }
        }
        
        // Reset color to white to avoid affecting subsequent renders
        g2.color = kha.Color.White;
    }

    // Additional private variables needed for emission timing
    private var _emissionAccumulator:Float = 0.0;
    private var _burstTimer:Float = 0.0;
    private var _nextBurstInterval:Float = 0.0;

    // Private helper functions for particle management

    private function updateExistingParticles(deltaTime:Float):Void {
        var i = 0;
        while (i < _activeParticles) {
            // Update particle lifetime
            _lifetimes[i] -= deltaTime;
            
            if (_lifetimes[i] <= 0) {
                // Remove dead particle by swapping with last active particle
                removeParticleAtIndex(i);
                // Don't increment i since we swapped a new particle to this position
            } else {
                // Update particle position based on velocity
                if (i < _bezierPaths.length && _bezierPaths[i] != null) {
                    // Update position along bezier curve
                    updateParticleAlongBezierPath(i, deltaTime);
                } else {
                    // Standard linear movement for non-spark particles
                    _particles[i].x += _velocities[i].x * deltaTime;
                    _particles[i].y += _velocities[i].y * deltaTime;
                }
                
                // Apply fade out if enabled
                if (fadeOut) {
                    var lifeRatio = _lifetimes[i] / particleLifetime;
                    var alpha = Math.max(0, Math.min(1, lifeRatio));
                    _colors[i] = kha.Color.fromFloats(
                        color.R,
                        color.G,
                        color.B,
                        alpha
                    );
                }
                
                i++;
            }
        }
    }

    private function handleContinuousEmission(deltaTime:Float, numParticles:Null<Int>, uniform:Null<Bool>, curvature:Null<FastVector2>):Void {
        var particlesToEmit = numParticles != null ? numParticles : 10;
        var isUniform = uniform != null ? uniform : false;
        
        if (isUniform) {
            // For uniform emission, emit at regular intervals
            _emissionAccumulator += deltaTime * emissionRate;
            
            while (_emissionAccumulator >= 1.0 && _activeParticles < maxParticles) {
                for (i in 0...particlesToEmit) {
                    if (_activeParticles >= maxParticles) break;
                    emitParticle(curvature);
                }
                _emissionAccumulator -= 1.0;
            }
        } else {
            // For non-uniform emission, use random intervals
            _emissionAccumulator += deltaTime * emissionRate;
            
            var emitCount = Math.floor(_emissionAccumulator);
            if (emitCount > 0) {
                emitCount = cast Math.min(emitCount * particlesToEmit, maxParticles - _activeParticles);
                for (i in 0...emitCount) {
                    emitParticle(curvature);
                }
                _emissionAccumulator -= Math.floor(_emissionAccumulator);
            }
        }
    }

    private function handleBurstEmission(deltaTime:Float, count:Int, interval:Float, curvature:Null<FastVector2>):Void {
        _burstTimer += deltaTime;
        
        if (_burstTimer >= interval) {
            var particlesToEmit:Int = cast Math.min(count, maxParticles - _activeParticles);
            for (i in 0...particlesToEmit) {
                emitParticle(curvature);
            }
            _burstTimer = 0.0;
        }
    }

    private function handleRandomBurstEmission(deltaTime:Float, minCount:Int, maxCount:Int, minInterval:Float, maxInterval:Float, curvature:Null<FastVector2>):Void {
        if (_nextBurstInterval <= 0.0) {
            // Set next burst interval randomly
            _nextBurstInterval = minInterval + Math.random() * (maxInterval - minInterval);
        }
        
        _burstTimer += deltaTime;
        
        if (_burstTimer >= _nextBurstInterval) {
            var count = minCount + Math.floor(Math.random() * (maxCount - minCount + 1));
            var particlesToEmit:Int = cast Math.min(count, maxParticles - _activeParticles);
            
            for (i in 0...particlesToEmit) {
                emitParticle(curvature);
            }
            
            _burstTimer = 0.0;
            _nextBurstInterval = 0.0; // Reset so a new interval will be calculated
        }
    }

    private function handleSparkEmission(deltaTime:Float, count:Int, curvature:Null<FastVector2>):Void {
        // Use emission rate to determine when to emit particles
        _emissionAccumulator += deltaTime * emissionRate;
        
        // Emit when accumulator reaches 1.0 (based on emission rate)
        while (_emissionAccumulator >= 1.0 && _activeParticles < maxParticles) {
            // Emit the specified count of particles
            var particlesToEmit:Int = cast Math.min(count, maxParticles - _activeParticles);
            
            for (i in 0...particlesToEmit) {
                if (_activeParticles >= maxParticles) break;
                emitSparkParticleWithBezier(curvature);
            }
            
            _emissionAccumulator -= 1.0;
        }
    }

    private function emitParticle(curvature:Null<FastVector2>):Void {
        if (_activeParticles >= maxParticles) {
            return;
        }
        
        // Expand arrays if needed
        while (_particles.length <= _activeParticles) {
            _particles.push(new FastVector2());
            _velocities.push(new FastVector2());
            _lifetimes.push(0.0);
            _sizes.push(0.0);
            _colors.push(kha.Color.White);
        }
        
        var randomSpread = (Math.random() - 0.5) * spread; // Random spread factor
        var oppositeVelocity = new FastVector2(-velocity.y, velocity.x);

        // Set particle position
        _particles[_activeParticles].setFrom(new FastVector2(
            position.x + oppositeVelocity.x * randomSpread,
            position.y + oppositeVelocity.y * randomSpread
        ));

        if (variableSpeed) {
            var speedVariation = 0.5 + Math.random();
            // Set random velocity based on base velocity
            _velocities[_activeParticles].setFrom(new FastVector2(
                velocity.x * speedVariation, // Random variation
                velocity.y * speedVariation
            ));
        } else {
            // Use fixed velocity
            _velocities[_activeParticles].setFrom(velocity);
        }
        
        // Apply curvature if specified
        if (curvature != null) {
            var randomFactor = (Math.random() - 0.5) * 2.0; // -1 to 1
            _particles[_activeParticles].x += curvature.x * randomFactor;
            _particles[_activeParticles].y += curvature.y * randomFactor;
        }
        
        // Set particle lifetime
        _lifetimes[_activeParticles] = particleLifetime;
        
        // Set particle size
        if (variableSize) {
            var variation = 0.5 + Math.random();
            _sizes[_activeParticles] = particleSize * variation;
        } else {
            _sizes[_activeParticles] = particleSize;
        }
        
        // Set particle color
        _colors[_activeParticles] = color;
        
        _activeParticles++;
    }

    private function emitSparkParticleWithBezier(curvature:Null<FastVector2>):Void {
        if (_activeParticles >= maxParticles) {
            return;
        }
        
        // Initialize bezier arrays if needed
        if (_bezierPaths == null) {
            _bezierPaths = [];
            _pathProgress = [];
        }
        
        // Expand arrays if needed
        while (_particles.length <= _activeParticles) {
            _particles.push(new FastVector2());
            _velocities.push(new FastVector2());
            _lifetimes.push(0.0);
            _sizes.push(0.0);
            _colors.push(kha.Color.White);
            _bezierPaths.push(null);
            _pathProgress.push(0.0);
        }
        
        // Set starting position with spread
        var startPos = new FastVector2(position.x, position.y);
        if (spread > 0.0) {
            var spreadAngle = Math.random() * Math.PI * 2;
            var spreadDistance = Math.random() * spread;
            startPos.x += Math.cos(spreadAngle) * spreadDistance;
            startPos.y += Math.sin(spreadAngle) * spreadDistance;
        }
        
        // Generate bezier curve for this spark
        var bezierPath = generateSparkBezierPath(startPos, curvature);
        _bezierPaths[_activeParticles] = bezierPath;
        _pathProgress[_activeParticles] = 0.0;
        
        // Set initial particle position
        _particles[_activeParticles].setFrom(startPos);
        
        // Initialize velocity (used to determine speed along path)
        if (variableSpeed) {
            var speedVariation = 0.5 + Math.random();
            _velocities[_activeParticles].setFrom(new FastVector2(
                velocity.x * speedVariation,
                velocity.y * speedVariation
            ));
        } else {
            _velocities[_activeParticles].setFrom(velocity);
        }
        
        // Set particle properties
        _lifetimes[_activeParticles] = particleLifetime;
        
        if (variableSize) {
            var variation = 0.5 + Math.random();
            _sizes[_activeParticles] = particleSize * variation;
        } else {
            _sizes[_activeParticles] = particleSize;
        }
        
        _colors[_activeParticles] = color;
        _activeParticles++;
    }

    private function generateSparkBezierPath(startPos:FastVector2, curvature:Null<FastVector2>):BezierPath {
        var baseDistance = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y) * particleLifetime;
        
        // Calculate end point based on velocity direction and lifetime
        var endPoint = new FastVector2(
            startPos.x + velocity.x * particleLifetime,
            startPos.y + velocity.y * particleLifetime
        );
        
        // Generate control points for the bezier curve
        var cp1:FastVector2;
        var cp2:FastVector2;
        
        if (curvature != null) {
            // Use curvature to create control points that bend the path
            var curveIntensity1 = (Math.random() - 0.5) * 2.0; // -1 to 1
            var curveIntensity2 = (Math.random() - 0.5) * 2.0; // -1 to 1
            
            // First control point (closer to start)
            cp1 = new FastVector2(
                startPos.x + (velocity.x * 0.33 * particleLifetime) + (curvature.x * curveIntensity1),
                startPos.y + (velocity.y * 0.33 * particleLifetime) + (curvature.y * curveIntensity1)
            );
            
            // Second control point (closer to end)
            cp2 = new FastVector2(
                startPos.x + (velocity.x * 0.66 * particleLifetime) + (curvature.x * curveIntensity2),
                startPos.y + (velocity.y * 0.66 * particleLifetime) + (curvature.y * curveIntensity2)
            );
        } else {
            // Without curvature, create a slight arc for natural spark behavior
            var perpVector = new FastVector2(-velocity.y, velocity.x); // Perpendicular to velocity
            perpVector.length = baseDistance * 0.1; // Small arc
            
            var randomArc1 = (Math.random() - 0.5) * 0.5; // -0.25 to 0.25
            var randomArc2 = (Math.random() - 0.5) * 0.5;
            
            cp1 = new FastVector2(
                startPos.x + (velocity.x * 0.33 * particleLifetime) + (perpVector.x * randomArc1),
                startPos.y + (velocity.y * 0.33 * particleLifetime) + (perpVector.y * randomArc1)
            );
            
            cp2 = new FastVector2(
                startPos.x + (velocity.x * 0.66 * particleLifetime) + (perpVector.x * randomArc2),
                startPos.y + (velocity.y * 0.66 * particleLifetime) + (perpVector.y * randomArc2)
            );
        }
        
        return new BezierPath(startPos, cp1, cp2, endPoint);
    }

    private function updateParticleAlongBezierPath(particleIndex:Int, deltaTime:Float):Void {
        var bezierPath = _bezierPaths[particleIndex];
        var velocity = _velocities[particleIndex];
        
        // Calculate speed along the path based on velocity magnitude
        var speed = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
        
        // Calculate approximate path length for proper speed scaling
        var pathLength = approximateBezierLength(bezierPath);
        var progressSpeed = speed / pathLength;
        
        // Update progress along the path
        _pathProgress[particleIndex] += progressSpeed * deltaTime;
        _pathProgress[particleIndex] = Math.min(1.0, _pathProgress[particleIndex]);
        
        // Calculate position on bezier curve
        var newPos = evaluateBezierCurve(bezierPath, _pathProgress[particleIndex]);
        _particles[particleIndex].setFrom(newPos);
    }

    // Cubic bezier curve evaluation
    private function evaluateBezierCurve(path:BezierPath, t:Float):FastVector2 {
        // Clamp t to [0, 1]
        t = Math.max(0.0, Math.min(1.0, t));
        
        var oneMinusT = 1.0 - t;
        var oneMinusTSquared = oneMinusT * oneMinusT;
        var oneMinusTCubed = oneMinusTSquared * oneMinusT;
        var tSquared = t * t;
        var tCubed = tSquared * t;
        
        var x = oneMinusTCubed * path.startPoint.x +
                3.0 * oneMinusTSquared * t * path.controlPoint1.x +
                3.0 * oneMinusT * tSquared * path.controlPoint2.x +
                tCubed * path.endPoint.x;
                
        var y = oneMinusTCubed * path.startPoint.y +
                3.0 * oneMinusTSquared * t * path.controlPoint1.y +
                3.0 * oneMinusT * tSquared * path.controlPoint2.y +
                tCubed * path.endPoint.y;
        
        return new FastVector2(x, y);
    }

    // Approximate bezier curve length for speed calculations
    private function approximateBezierLength(path:BezierPath):Float {
        var segments = 10;
        var totalLength = 0.0;
        var prevPoint = path.startPoint;
        
        for (i in 1...segments + 1) {
            var t = i / segments;
            var currentPoint = evaluateBezierCurve(path, t);
            var segmentLength = Math.sqrt(
                Math.pow(currentPoint.x - prevPoint.x, 2) + 
                Math.pow(currentPoint.y - prevPoint.y, 2)
            );
            totalLength += segmentLength;
            prevPoint = currentPoint;
        }
        
        return totalLength;
    }

    // Update the removeParticleAtIndex function to handle bezier paths:

    private function removeParticleAtIndex(index:Int):Void {
        if (index >= _activeParticles || _activeParticles <= 0) {
            return;
        }
        
        // Swap with last active particle
        var lastIndex = _activeParticles - 1;
        
        _particles[index].setFrom(_particles[lastIndex]);
        _velocities[index].setFrom(_velocities[lastIndex]);
        _lifetimes[index] = _lifetimes[lastIndex];
        _sizes[index] = _sizes[lastIndex];
        _colors[index] = _colors[lastIndex];
        
        // Handle bezier path swapping if arrays exist
        if (_bezierPaths != null && index < _bezierPaths.length && lastIndex < _bezierPaths.length) {
            _bezierPaths[index] = _bezierPaths[lastIndex];
            _bezierPaths[lastIndex] = null;
        }
        
        if (_pathProgress != null && index < _pathProgress.length && lastIndex < _pathProgress.length) {
            _pathProgress[index] = _pathProgress[lastIndex];
            _pathProgress[lastIndex] = 0.0;
        }
        
        _activeParticles--;
    }


}