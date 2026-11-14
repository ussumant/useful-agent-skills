// wallpaper-lab: swaps the Claude desktop app's backdrop live, with no reload, so a scene is tested in seconds.
//
//   1. write an SVG to <lab>/scene.svg (and, if wanted, theme settings to <lab>/look.json)
//   2. write a new word to <lab>/tick
//   3. within 1.5 s the lab shows that SVG as the scene wallpaper-lab-<word> and writes <lab>/drawn.json
//
// An empty or missing <lab>/tick clears the theme. scripts/install_lab.sh copies this mod into a session's mods folder
// and fills in the lab folder below. Take the mod out when the testing is done.
import type { EngineInterface, Register, ThemeBackdropGlass } from 'claude-code'

const LAB = '__LAB_DIR__'
const PLUGIN = 'wallpaper-lab'
const PREFIX = 'wallpaper-lab-'
const EMPTY =
  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 2560 1600" preserveAspectRatio="xMidYMid slice"><rect width="2560" height="1600" fill="#555"/></svg>'

/** <lab>/look.json: the glass over the scene (none by default, so the scene shows clearly) and the window's mode. */
type LabLook = { glass?: ThemeBackdropGlass | false; override?: 'light' | 'dark' }

const lab: { tick: string; svg: string; isWatching: boolean; draws: number } = { tick: '', svg: EMPTY, isWatching: false, draws: 0 }

async function readOr($: EngineInterface, path: string, otherwise: string): Promise<string> {
  try {
    return await $.fs.read(path)
  } catch {
    return otherwise
  }
}

async function watch($: EngineInterface): Promise<void> {
  const tick = (await readOr($, `${LAB}/tick`, '')).replace(/[^A-Za-z0-9_-]/g, '').slice(0, 40)

  if (tick === lab.tick) {
    return
  }
  lab.tick = tick
  if (tick === '') {
    // A clear takes away whichever theme stands, another mod's too. A mod under test sets its own again on reload.
    await $.theme.clear()

    return
  }
  lab.svg = await readOr($, `${LAB}/scene.svg`, EMPTY)
  let look: LabLook = {}

  try {
    look = JSON.parse(await readOr($, `${LAB}/look.json`, '{}')) as LabLook
  } catch {
    look = {}
  }

  await $.theme.set({
    backdrop: { scene: `${PREFIX}${tick}`, glass: look.glass ?? { blur: 0, opacity: 0 } },
    ...(look.override === undefined ? {} : { overrideColorScheme: look.override }),
  })
}

async function noteDraw($: EngineInterface, scene: string, chars: number): Promise<void> {
  lab.draws += 1
  try {
    await $.fs.write(`${LAB}/drawn.json`, JSON.stringify({ scene, chars, draws: lab.draws, at: new Date().toISOString() }))
  } catch {
    // the scene still draws if the note can't be written
  }
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    if (!lab.isWatching) {
      lab.isWatching = true
      $.clock.every(1500, () => {
        void watch($)
      })
    }

    return next(e)
  })

  on('ui.render', { component: 'Backdrop' }, ($, e, next) => {
    if (e.surface !== 'desktop' || e.props.plugin !== PLUGIN || !e.props.scene.startsWith(PREFIX)) {
      return next(e)
    }
    const { Svg } = $.ui.resolve(e)

    void noteDraw($, e.props.scene, lab.svg.length)

    return <Svg source={lab.svg} alt="A wallpaper under test" isInteractive />
  })
}
