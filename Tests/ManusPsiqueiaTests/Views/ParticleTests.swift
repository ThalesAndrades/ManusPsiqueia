import XCTest
@testable import ManusPsiqueia

class ParticleTests: XCTestCase {

    func testParticleInitialization() {
        let particle = Particle(x: 10.0, y: 20.0, size: 5.0, speed: 1.0, direction: 0.5)
        XCTAssertNotNil(particle, "Particle should be initializable")
        XCTAssertEqual(particle.x, 10.0)
        XCTAssertEqual(particle.y, 20.0)
        XCTAssertEqual(particle.size, 5.0)
        XCTAssertEqual(particle.speed, 1.0)
        XCTAssertEqual(particle.direction, 0.5)
    }

    func testParticleMovement() {
        var particle = Particle(x: 0.0, y: 0.0, size: 5.0, speed: 1.0, direction: 0.0) // Moving right
        particle.move()
        XCTAssertEqual(particle.x, 1.0)
        XCTAssertEqual(particle.y, 0.0)

        particle = Particle(x: 0.0, y: 0.0, size: 5.0, speed: 1.0, direction: .pi / 2) // Moving up
        particle.move()
        XCTAssertEqual(particle.x, 0.0, accuracy: 0.0001)
        XCTAssertEqual(particle.y, 1.0, accuracy: 0.0001)
    }

    func testParticleUpdate() {
        var particle = Particle(x: 0.0, y: 0.0, size: 5.0, speed: 1.0, direction: 0.0)
        particle.update(width: 100, height: 100)
        // Assuming update moves the particle and handles boundaries
        XCTAssertNotEqual(particle.x, 0.0)
    }
}


