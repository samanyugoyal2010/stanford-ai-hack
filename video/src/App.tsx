import { useEffect, useMemo, useState } from 'react'
import { AnimatePresence, motion } from 'motion/react'

const scenes = [
  'hero',
  'study',
  'stuck',
  'detecting',
  'guidance',
  'architecture',
  'privacy',
  'graph',
  'vision',
  'outro',
] as const

type Scene = (typeof scenes)[number]

const sceneDurations: Record<Scene, number> = {
  hero: 5200,
  study: 5200,
  stuck: 4600,
  detecting: 4200,
  guidance: 5600,
  architecture: 5200,
  privacy: 4500,
  graph: 4500,
  vision: 4700,
  outro: 5200,
}

const architectureItems = [
  { title: 'Observe', subtitle: 'ScreenCaptureKit' },
  { title: 'Understand', subtitle: 'Vision + Speech' },
  { title: 'Reason', subtitle: 'Gemma' },
  { title: 'Guide', subtitle: 'Socratic Questions' },
  { title: 'Remember', subtitle: 'Learning Memory' },
]

const masteryBars = [
  { label: 'Calculus', width: '92%' },
  { label: 'Geometry', width: '72%' },
  { label: 'Physics', width: '42%' },
  { label: 'Chemistry', width: '18%' },
]

function App() {
  const [sceneIndex, setSceneIndex] = useState(0)
  const scene = scenes[sceneIndex]

  useEffect(() => {
    const timer = window.setTimeout(() => {
      setSceneIndex((current) => (current + 1) % scenes.length)
    }, sceneDurations[scene])
    return () => window.clearTimeout(timer)
  }, [scene])

  const progress = useMemo(
    () => ((sceneIndex + 1) / scenes.length) * 100,
    [sceneIndex],
  )

  return (
    <div className="relative h-full w-full overflow-hidden bg-[#05070A] text-white">
      <div className="pointer-events-none absolute inset-0">
        <motion.div
          className="absolute left-1/2 top-[-8%] h-[42rem] w-[42rem] -translate-x-1/2 rounded-full bg-indigo-500/10 blur-3xl"
          animate={{ y: [0, 18, 0], scale: [1, 1.08, 1] }}
          transition={{ duration: 18, repeat: Infinity, ease: 'easeInOut' }}
        />
        <motion.div
          className="absolute right-[-10%] top-[28%] h-[30rem] w-[30rem] rounded-full bg-white/5 blur-3xl"
          animate={{ y: [0, -20, 0], x: [0, 12, 0] }}
          transition={{ duration: 20, repeat: Infinity, ease: 'easeInOut' }}
        />
      </div>

      <div className="pointer-events-none absolute left-0 top-0 h-[1px] w-full bg-white/10">
        <motion.div
          className="h-full bg-gradient-to-r from-transparent via-indigo-400 to-transparent"
          initial={{ width: '0%' }}
          animate={{ width: `${progress}%` }}
          transition={{ type: 'spring', stiffness: 40, damping: 20 }}
        />
      </div>

      <AnimatePresence mode="wait">
        <motion.main
          key={scene}
          className="flex h-full w-full items-center justify-center px-6 py-8 sm:px-10 lg:px-16"
          initial={{ opacity: 0, scale: 0.99, filter: 'blur(12px)' }}
          animate={{ opacity: 1, scale: 1, filter: 'blur(0px)' }}
          exit={{ opacity: 0, scale: 1.01, filter: 'blur(12px)' }}
          transition={{ type: 'spring', stiffness: 42, damping: 16, mass: 1.1 }}
        >
          <SceneFrame scene={scene} />
        </motion.main>
      </AnimatePresence>
    </div>
  )
}

function SceneFrame({ scene }: { scene: Scene }) {
  switch (scene) {
    case 'hero':
      return <Hero />
    case 'study':
      return <StudyScene />
    case 'stuck':
      return <StuckScene />
    case 'detecting':
      return <DetectingScene />
    case 'guidance':
      return <GuidanceScene />
    case 'architecture':
      return <ArchitectureScene />
    case 'privacy':
      return <PrivacyScene />
    case 'graph':
      return <GraphScene />
    case 'vision':
      return <VisionScene />
    case 'outro':
      return <OutroScene />
  }
}

function Hero() {
  return (
    <div className="flex min-h-[85vh] w-full items-center justify-center">
      <motion.div
        className="text-center"
        initial={{ opacity: 0, y: 22 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ type: 'spring', stiffness: 50, damping: 18, delay: 0.1 }}
      >
        <motion.div
          className="mb-5 text-[0.65rem] uppercase tracking-[0.5em] text-white/45"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 1.1, delay: 0.35 }}
        >
          Nudge
        </motion.div>
        <motion.h1
          className="max-w-4xl text-5xl font-medium tracking-[-0.06em] text-white sm:text-7xl lg:text-8xl"
          initial={{ opacity: 0, y: 18 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ type: 'spring', stiffness: 40, damping: 16, delay: 0.45 }}
        >
          The AI tutor that knows you&apos;re stuck before you do.
        </motion.h1>
      </motion.div>
    </div>
  )
}

function MacWindow({ children }: { children: React.ReactNode }) {
  return (
    <motion.div
      className="relative mx-auto w-full max-w-6xl overflow-hidden rounded-[2rem] border border-white/10 bg-white/[0.045] shadow-glass backdrop-blur-2xl"
      initial={{ opacity: 0, y: 36, scale: 0.98 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      transition={{ type: 'spring', stiffness: 46, damping: 18 }}
    >
      <div className="flex items-center gap-2 border-b border-white/8 px-5 py-4">
        <span className="h-3 w-3 rounded-full bg-[#ff5f57]" />
        <span className="h-3 w-3 rounded-full bg-[#febc2e]" />
        <span className="h-3 w-3 rounded-full bg-[#28c840]" />
      </div>
      {children}
    </motion.div>
  )
}

function Cursor() {
  return (
    <motion.div
      className="absolute h-4 w-4 rounded-full border border-white/70 bg-white/12 shadow-[0_0_22px_rgba(255,255,255,0.2)]"
      animate={{ x: [0, 8, 0], y: [0, 10, 0] }}
      transition={{ duration: 4.5, repeat: Infinity, ease: 'easeInOut' }}
    />
  )
}

function StudyScene() {
  return (
    <div className="w-full">
      <MacWindow>
        <div className="grid gap-8 p-8 lg:grid-cols-[1.15fr_0.85fr] lg:p-10">
          <div className="space-y-6">
            <div className="space-y-3">
              <div className="text-xs uppercase tracking-[0.4em] text-white/35">Calculus I</div>
              <h2 className="text-4xl font-medium tracking-[-0.05em] text-white">
                Differentiate the function.
              </h2>
              <p className="max-w-xl text-sm leading-6 text-white/48">
                A quiet worksheet. A long pause. A cursor that keeps returning to the same line.
              </p>
            </div>
            <div className="rounded-[1.5rem] border border-white/10 bg-black/30 p-5">
              <p className="text-base leading-8 text-white/75">
                f(x) = x<sup>4</sup> + 3x<sup>2</sup> - 7x
              </p>
              <div className="mt-8 rounded-[1rem] border border-white/8 bg-white/[0.03] p-4">
                <div className="h-12 rounded-xl bg-white/[0.04]" />
                <div className="mt-3 h-12 rounded-xl bg-white/[0.06] w-[64%]" />
              </div>
            </div>
          </div>
          <div className="relative min-h-[18rem] rounded-[1.75rem] border border-white/10 bg-[#0A0D12] p-6">
            <div className="absolute left-12 top-16">
              <Cursor />
            </div>
            <motion.div
              className="absolute bottom-6 right-6 rounded-full border border-white/10 bg-white/[0.04] px-4 py-2 text-xs tracking-[0.3em] text-white/50"
              animate={{ opacity: [0.45, 0.72, 0.45] }}
              transition={{ duration: 2.8, repeat: Infinity }}
            >
              typing...
            </motion.div>
          </div>
        </div>
      </MacWindow>
    </div>
  )
}

function StuckScene() {
  return (
    <div className="relative flex w-full max-w-6xl items-center justify-center">
      <motion.div
        className="absolute inset-0 rounded-[2.5rem] border border-white/5 bg-white/[0.02]"
        animate={{ opacity: [0.22, 0.42, 0.22] }}
        transition={{ duration: 2.4, repeat: Infinity }}
      />
      <div className="relative w-full rounded-[2.5rem] p-10 sm:p-14">
        <div className="max-w-3xl">
          <motion.h2
            className="text-4xl font-medium tracking-[-0.06em] text-white sm:text-6xl"
            initial={{ opacity: 0, y: 18 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ type: 'spring', stiffness: 40, damping: 16 }}
          >
            Every student gets stuck.
          </motion.h2>
          <p className="mt-6 max-w-xl text-base leading-7 text-white/40">
            Not with drama. Not with noise. Just a pause, a delete, and the same line typed twice.
          </p>
          <div className="mt-14 flex gap-4 text-xs uppercase tracking-[0.35em] text-white/24">
            <span>pause</span>
            <span>delete</span>
            <span>hesitate</span>
          </div>
        </div>
      </div>
    </div>
  )
}

function DetectingScene() {
  return (
    <div className="w-full max-w-4xl">
      <div className="rounded-[2rem] border border-white/10 bg-white/[0.04] p-8 shadow-glass backdrop-blur-2xl sm:p-10">
        <motion.div
          className="inline-flex rounded-full border border-white/10 bg-white/[0.05] px-4 py-2 text-xs uppercase tracking-[0.35em] text-white/55"
          animate={{ opacity: [0.5, 1, 0.5] }}
          transition={{ duration: 3.2, repeat: Infinity }}
        >
          Detecting confusion...
        </motion.div>
        <div className="mt-8 space-y-6">
          <TranscriptBubble text="I don't understand this." />
          <ConfidenceMeter value={38} />
        </div>
      </div>
    </div>
  )
}

function GuidanceScene() {
  return (
    <div className="grid w-full max-w-6xl gap-6 lg:grid-cols-[0.9fr_1.1fr]">
      <div className="rounded-[2rem] border border-white/10 bg-white/[0.03] p-8">
        <div className="mb-5 text-xs uppercase tracking-[0.35em] text-white/35">Student</div>
        <TranscriptBubble text="I don't understand this." />
        <div className="mt-4 rounded-[1.5rem] border border-white/10 bg-black/30 p-5 text-sm leading-7 text-white/65">
          The student is not looking for the answer. They need the next question.
        </div>
      </div>
      <motion.div
        className="relative overflow-hidden rounded-[2rem] border border-white/10 bg-white/[0.06] p-8 shadow-glass"
        initial={{ x: 36, opacity: 0 }}
        animate={{ x: 0, opacity: 1 }}
        transition={{ type: 'spring', stiffness: 34, damping: 16 }}
      >
        <div className="absolute inset-0 bg-gradient-to-br from-indigo-500/10 via-transparent to-transparent" />
        <div className="relative">
          <div className="text-xs uppercase tracking-[0.35em] text-white/36">Nudge</div>
          <h3 className="mt-4 text-4xl font-medium tracking-[-0.06em] text-white">
            What rule connects the exponent to its derivative?
          </h3>
          <div className="mt-8 grid gap-3 sm:grid-cols-2">
            {['Observe the pattern', 'Try one step first', 'Explain the rule aloud', 'Check the sign'].map((item) => (
              <div key={item} className="rounded-[1.1rem] border border-white/10 bg-black/20 px-4 py-3 text-sm text-white/72">
                {item}
              </div>
            ))}
          </div>
        </div>
      </motion.div>
    </div>
  )
}

function TutorCard({ title, subtitle }: { title: string; subtitle: string }) {
  return (
    <motion.div
      layout
      className="rounded-[1.6rem] border border-white/10 bg-white/[0.045] p-5 shadow-glass backdrop-blur-2xl"
      transition={{ type: 'spring', stiffness: 36, damping: 16 }}
    >
      <div className="text-sm font-medium text-white">{title}</div>
      <div className="mt-2 text-xs uppercase tracking-[0.3em] text-white/38">{subtitle}</div>
    </motion.div>
  )
}

function ArchitectureScene() {
  return (
    <div className="w-full max-w-6xl">
      <div className="mb-8 text-center">
        <div className="text-xs uppercase tracking-[0.5em] text-white/35">Architecture</div>
        <h2 className="mt-4 text-4xl font-medium tracking-[-0.06em] text-white sm:text-6xl">
          Quiet systems, working together.
        </h2>
      </div>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
        {architectureItems.map((item, index) => (
          <motion.div
            key={item.title}
            initial={{ y: 16, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ type: 'spring', stiffness: 40, damping: 16, delay: index * 0.08 }}
          >
            <TutorCard title={item.title} subtitle={item.subtitle} />
          </motion.div>
        ))}
      </div>
    </div>
  )
}

function PrivacyScene() {
  return (
    <div className="grid w-full max-w-5xl gap-8 lg:grid-cols-[0.9fr_1.1fr]">
      <div className="rounded-[2rem] border border-white/10 bg-white/[0.04] p-8 shadow-glass">
        <div className="flex h-16 w-16 items-center justify-center rounded-[1.5rem] border border-white/10 bg-white/[0.05] text-2xl">
          🔒
        </div>
        <h2 className="mt-8 text-4xl font-medium tracking-[-0.06em] text-white">
          Private by Design.
        </h2>
        <p className="mt-4 max-w-md text-base leading-7 text-white/46">
          Everything stays on-device. Screen. Voice. Memory. No data leaves your Mac.
        </p>
      </div>
      <div className="rounded-[2rem] border border-white/8 bg-black/30 p-8">
        <div className="space-y-4 text-sm text-white/68">
          <div className="flex items-center justify-between rounded-2xl border border-white/8 bg-white/[0.03] px-5 py-4">
            <span>Screen</span>
            <span className="text-white/36">local</span>
          </div>
          <div className="flex items-center justify-between rounded-2xl border border-white/8 bg-white/[0.03] px-5 py-4">
            <span>Voice</span>
            <span className="text-white/36">local</span>
          </div>
          <div className="flex items-center justify-between rounded-2xl border border-white/8 bg-white/[0.03] px-5 py-4">
            <span>Memory</span>
            <span className="text-white/36">local</span>
          </div>
        </div>
      </div>
    </div>
  )
}

function GraphScene() {
  return (
    <div className="w-full max-w-6xl">
      <div className="mb-8">
        <div className="text-xs uppercase tracking-[0.5em] text-white/35">Mastery</div>
        <h2 className="mt-4 text-4xl font-medium tracking-[-0.06em] text-white sm:text-6xl">
          Learning that quietly accumulates.
        </h2>
      </div>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {masteryBars.map((bar, index) => (
          <motion.div
            key={bar.label}
            className="rounded-[1.6rem] border border-white/10 bg-white/[0.04] p-5"
            initial={{ opacity: 0, y: 14 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ type: 'spring', stiffness: 42, damping: 17, delay: index * 0.06 }}
          >
            <div className="flex items-end justify-between gap-4">
              <div>
                <div className="text-sm text-white">{bar.label}</div>
                <div className="mt-2 h-2 w-40 rounded-full bg-white/6">
                  <motion.div
                    className="h-full rounded-full bg-gradient-to-r from-indigo-400 to-white/80"
                    initial={{ width: '0%' }}
                    animate={{ width: bar.width }}
                    transition={{ type: 'spring', stiffness: 36, damping: 18, delay: 0.12 + index * 0.08 }}
                  />
                </div>
              </div>
              <div className="text-2xl font-medium tracking-[-0.05em] text-white/80">{bar.width}</div>
            </div>
          </motion.div>
        ))}
      </div>
    </div>
  )
}

function VisionScene() {
  return (
    <div className="max-w-5xl text-center">
      <div className="space-y-6">
        <div className="text-xs uppercase tracking-[0.5em] text-white/35">Vision</div>
        <h2 className="text-4xl font-medium tracking-[-0.06em] text-white sm:text-6xl lg:text-7xl">
          We&apos;re not building another chatbot.
        </h2>
        <motion.p
          className="text-3xl font-medium tracking-[-0.05em] text-white/78 sm:text-5xl"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.8, duration: 1.2 }}
        >
          We&apos;re building the operating system for learning.
        </motion.p>
      </div>
    </div>
  )
}

function OutroScene() {
  return (
    <div className="flex min-h-[80vh] w-full items-center justify-center text-center">
      <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 1.2 }}>
        <div className="text-[0.72rem] uppercase tracking-[0.5em] text-white/36">Nudge</div>
        <div className="mt-6 text-6xl font-medium tracking-[-0.06em] text-white sm:text-8xl">Nudge</div>
        <div className="mt-8 text-2xl font-medium tracking-[-0.04em] text-white/72 sm:text-4xl">
          Learn.
          <br />
          Don&apos;t just get answers.
        </div>
      </motion.div>
    </div>
  )
}

function TranscriptBubble({ text }: { text: string }) {
  return (
    <motion.div
      className="inline-flex max-w-full rounded-[1.5rem] rounded-tl-md border border-white/10 bg-white/[0.05] px-5 py-4 text-sm leading-7 text-white/84 shadow-glass"
      initial={{ opacity: 0, y: 12, scale: 0.98 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      transition={{ type: 'spring', stiffness: 45, damping: 18 }}
    >
      {text}
    </motion.div>
  )
}

function ConfidenceMeter({ value }: { value: number }) {
  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between text-xs uppercase tracking-[0.35em] text-white/34">
        <span>Confidence</span>
        <span>{value}%</span>
      </div>
      <div className="h-2 overflow-hidden rounded-full bg-white/6">
        <motion.div
          className="h-full rounded-full bg-gradient-to-r from-white/30 via-indigo-400 to-white/90"
          initial={{ width: '18%' }}
          animate={{ width: `${value}%` }}
          transition={{ type: 'spring', stiffness: 36, damping: 16 }}
        />
      </div>
    </div>
  )
}

export default App
