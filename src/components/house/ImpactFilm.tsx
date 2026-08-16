import { Canvas, useFrame } from "@react-three/fiber";
import { Stars } from "@react-three/drei";
import { Bloom, EffectComposer, Vignette } from "@react-three/postprocessing";
import { Suspense, useMemo, useRef } from "react";
import * as THREE from "three";
import { IMPACT } from "@/hale/theia/impact-gauntlet";

const RE = 6.378;
const RT = 3.396;
const CONTACT_R = IMPACT.rContact / 1000;
const HIT = IMPACT.contactAt;
const LEN = IMPACT.duration;

function lerp(a: number, b: number, t: number) {
  return a + (b - a) * t;
}
function smooth(t: number) {
  const x = Math.max(0, Math.min(1, t));
  return x * x * (3 - 2 * x);
}

function useClock(startAt: number) {
  return (elapsed: number) => (((elapsed + startAt) % LEN) + LEN) % LEN;
}

function World({ startAt }: { startAt: number }) {
  const clock = useClock(startAt);
  const terra = useRef<THREE.Mesh>(null);
  const theia = useRef<THREE.Mesh>(null);
  const flash = useRef<THREE.PointLight>(null);
  const debris = useRef<THREE.InstancedMesh>(null);
  const luna = useRef<THREE.Mesh>(null);
  const dummy = useMemo(() => new THREE.Object3D(), []);
  const earthMap = useMemo(() => new THREE.TextureLoader().load("/textures/proto-earth.jpg"), []);
  const earthN = useMemo(() => new THREE.TextureLoader().load("/textures/earth-normal.jpg"), []);
  const marsMap = useMemo(() => new THREE.TextureLoader().load("/textures/mars.jpg"), []);
  const moonMap = useMemo(() => new THREE.TextureLoader().load("/textures/moon.jpg"), []);
  earthMap.colorSpace = THREE.SRGBColorSpace;
  marsMap.colorSpace = THREE.SRGBColorSpace;
  moonMap.colorSpace = THREE.SRGBColorSpace;

  const bits = useMemo(() => {
    const n = 1400;
    const a0 = new Float32Array(n);
    const r0 = new Float32Array(n);
    const vr = new Float32Array(n);
    const va = new Float32Array(n);
    const s = new Float32Array(n);
    const yk = new Float32Array(n);
    for (let i = 0; i < n; i++) {
      const h = Math.sin(i * 127.1 + 11.7) * 43758.5453;
      const u = h - Math.floor(h);
      const h2 = Math.sin(i * 91.7 + 3.1) * 23421.1;
      const u2 = h2 - Math.floor(h2);
      a0[i] = Math.PI / 4 + (u - 0.5) * 1.7;
      r0[i] = RE * (0.92 + u2 * 0.3);
      vr[i] = 2.8 + u * 11;
      va[i] = 0.08 + u2 * 0.28;
      s[i] = 0.04 + u * 0.22;
      yk[i] = (u2 - 0.5) * 0.55;
    }
    return { n, a0, r0, vr, va, s, yk };
  }, []);

  useFrame((state) => {
    const t = clock(state.clock.elapsedTime);
    const u = smooth(Math.min(1, t / HIT));
    const dist = lerp(28, CONTACT_R, u);
    const ang = Math.PI / 4;
    const tx = Math.cos(ang) * dist;
    const tz = Math.sin(ang) * dist;

    if (theia.current) {
      const alive = t < HIT + 0.45;
      theia.current.visible = alive;
      theia.current.position.set(tx, 0.35, tz);
      theia.current.rotation.y = t * 0.12;
      const crush = t < HIT ? 1 : Math.max(0.15, 1 - (t - HIT) * 2.2);
      theia.current.scale.setScalar(crush);
    }
    if (terra.current) {
      terra.current.rotation.y = t * 0.04;
      const mat = terra.current.material as THREE.MeshStandardMaterial;
      const melt = smooth(Math.min(1, Math.max(0, t - HIT) / 3));
      mat.emissive = new THREE.Color().setRGB(0.55 * melt, 0.16 * melt, 0.03 * melt);
      mat.emissiveIntensity = 0.15 + melt * 1.6;
      mat.roughness = 0.62 - melt * 0.2;
    }
    if (flash.current) {
      const hit = Math.max(0, t - HIT);
      flash.current.intensity = hit > 0 && hit < 3 ? 180 * Math.exp(-hit * 1.8) : 0;
      flash.current.position.set(Math.cos(ang) * RE * 0.7, 0.4, Math.sin(ang) * RE * 0.7);
    }
    if (debris.current) {
      const age = Math.max(0, t - HIT);
      debris.current.visible = age > 0.02;
      for (let i = 0; i < bits.n; i++) {
        const r = bits.r0[i]! + bits.vr[i]! * age * 1.15;
        const a = bits.a0[i]! + bits.va[i]! * age;
        dummy.position.set(Math.cos(a) * r, bits.yk[i]! * r * 0.35, Math.sin(a) * r);
        dummy.rotation.set(a, age * 2, a * 0.4);
        dummy.scale.setScalar(bits.s[i]! * (age < 0.4 ? age / 0.4 : 1));
        dummy.updateMatrix();
        debris.current.setMatrixAt(i, dummy.matrix);
      }
      debris.current.instanceMatrix.needsUpdate = true;
    }
    if (luna.current) {
      const g = smooth((t - 26) / 10);
      luna.current.visible = t > 26;
      const lr = lerp(RE * 2.4, RE * 5.6, g);
      const la = 0.55 + (t - 26) * 0.07;
      luna.current.position.set(Math.cos(la) * lr, 0.6, Math.sin(la) * lr);
      luna.current.scale.setScalar(lerp(0.12, 1.737, g));
      luna.current.rotation.y = t * 0.08;
    }

    const cam = state.camera;
    if (t < 12) {
      const k = smooth(t / 12);
      cam.position.set(lerp(16, 7.5, k), lerp(6.2, 3.4, k), lerp(26, 13, k));
    } else if (t < 18) {
      const k = smooth((t - 12) / 6);
      const shake = Math.exp(-(t - 12) * 2.2) * Math.sin(t * 70) * 0.22;
      cam.position.set(lerp(7.5, 6.2, k) + shake, lerp(3.4, 2.8, k), lerp(13, 11, k));
    } else if (t < 28) {
      const k = smooth((t - 18) / 10);
      cam.position.set(lerp(6.2, 14, k), lerp(2.8, 7.5, k), lerp(11, 28, k));
    } else {
      const k = smooth((t - 28) / 12);
      cam.position.set(lerp(14, 28, k), lerp(7.5, 13, k), lerp(28, 52, k));
    }
    cam.lookAt(tx * 0.35, 0.15, tz * 0.35);
  });

  return (
    <>
      <color attach="background" args={["#03040a"]} />
      <ambientLight intensity={0.07} />
      <directionalLight position={[-80, 30, -20]} intensity={2.6} color="#fff4d6" />
      <pointLight position={[-70, 24, -16]} intensity={40} color="#ffd7a0" distance={220} />
      <pointLight ref={flash} color="#fff2c8" distance={80} decay={2} />
      <Stars radius={400} depth={80} count={8000} factor={3.2} saturation={0} fade speed={0.15} />

      <mesh ref={terra}>
        <sphereGeometry args={[RE, 96, 96]} />
        <meshStandardMaterial
          map={earthMap}
          normalMap={earthN}
          roughness={0.58}
          metalness={0.04}
          emissive="#3a1408"
          emissiveIntensity={0.12}
        />
      </mesh>
      <mesh scale={1.045}>
        <sphereGeometry args={[RE, 64, 64]} />
        <meshBasicMaterial color="#7ec8ff" transparent opacity={0.09} side={THREE.BackSide} />
      </mesh>

      <mesh ref={theia}>
        <sphereGeometry args={[RT, 80, 80]} />
        <meshStandardMaterial map={marsMap} roughness={0.78} metalness={0.02} color="#c47a4a" />
      </mesh>

      <instancedMesh ref={debris} args={[undefined, undefined, bits.n]}>
        <dodecahedronGeometry args={[1, 0]} />
        <meshStandardMaterial color="#c48a58" roughness={0.7} emissive="#ff7a20" emissiveIntensity={0.45} />
      </instancedMesh>

      <mesh ref={luna}>
        <sphereGeometry args={[1, 48, 48]} />
        <meshStandardMaterial map={moonMap} roughness={0.9} emissive="#ffb070" emissiveIntensity={0.25} />
      </mesh>

      <EffectComposer>
        <Bloom intensity={1.15} luminanceThreshold={0.22} luminanceSmoothing={0.3} mipmapBlur />
        <Vignette eskil={false} offset={0.15} darkness={0.72} />
      </EffectComposer>
    </>
  );
}

export function ImpactFilm({ startAt = 0 }: { startAt?: number }) {
  return (
    <Canvas
      className="h-full w-full"
      camera={{ fov: 40, near: 0.2, far: 500, position: [28, 12, 58] }}
      dpr={[1, 1.75]}
      gl={{ antialias: true, toneMapping: THREE.ACESFilmicToneMapping, toneMappingExposure: 1.15 }}
    >
      <Suspense fallback={null}>
        <World startAt={startAt} />
      </Suspense>
    </Canvas>
  );
}
