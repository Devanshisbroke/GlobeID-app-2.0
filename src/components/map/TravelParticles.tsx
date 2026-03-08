import React, { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { airports, latLngToVector3 } from "@/lib/airports";
import { getHubs } from "@/lib/destinationAnalytics";

const GLOBE_RADIUS = 1;
const PARTICLE_COUNT = 200;

const TravelParticles: React.FC = () => {
  const meshRef = useRef<THREE.InstancedMesh>(null);
  const dummy = useMemo(() => new THREE.Object3D(), []);

  const hubs = useMemo(() => getHubs(), []);

  const particles = useMemo(() => {
    return Array.from({ length: PARTICLE_COUNT }, (_, i) => {
      const hub = hubs[i % hubs.length];
      const airport = airports.find((a) => a.iata === hub.iata);
      if (!airport) return { lat: 0, lng: 0, speed: 0.1, offset: Math.random() * Math.PI * 2, radius: 0.02 };
      return {
        lat: airport.lat + (Math.random() - 0.5) * 20,
        lng: airport.lng + (Math.random() - 0.5) * 20,
        speed: 0.02 + Math.random() * 0.05,
        offset: Math.random() * Math.PI * 2,
        radius: 0.005 + Math.random() * 0.01,
      };
    });
  }, [hubs]);

  useFrame(({ clock }) => {
    if (!meshRef.current) return;
    const t = clock.getElapsedTime();

    particles.forEach((p, i) => {
      const lat = p.lat + Math.sin(t * p.speed + p.offset) * 5;
      const lng = p.lng + Math.cos(t * p.speed * 0.7 + p.offset) * 5;
      const pos = latLngToVector3(lat, lng, GLOBE_RADIUS + 0.02 + Math.sin(t + p.offset) * 0.01);
      dummy.position.set(...pos);
      dummy.scale.setScalar(p.radius * (0.8 + Math.sin(t * 2 + p.offset) * 0.2));
      dummy.updateMatrix();
      meshRef.current!.setMatrixAt(i, dummy.matrix);
    });
    meshRef.current.instanceMatrix.needsUpdate = true;
  });

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, PARTICLE_COUNT]}>
      <sphereGeometry args={[1, 6, 6]} />
      <meshBasicMaterial color="#6bc5ff" transparent opacity={0.6} />
    </instancedMesh>
  );
};

export default TravelParticles;
