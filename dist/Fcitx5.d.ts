type Child = ({
  Description: string
  Option: string
  Type: string
  Value: string
} & ({
  Children: null
  DefaultValue: any
} | {
  Children: Child[]
}) & { [key: string]: any })

export type Config = {
  Children: Child[]
} | {
  ERROR: string
}

export interface MenuAction {
  id: number
  desc: string
  checked?: boolean
  separator?: boolean
  children?: MenuAction[]
}

interface AddonCategory {
  addons: {
    comment: string
    id: string
    name: string
  }[]
  id: number
  name: string
}

interface FS {
  mkdir: (path: string) => void
  readdir: (path: string) => string[]
  writeFile: (path: string, data: Uint8Array) => void
}

interface EM_MODULE {
  ccall: (name: string, retType: WASM_TYPE, argsType: WASM_TYPE[], args: any[]) => any
  onRuntimeInitialized: () => void
  FS: FS
}

export interface FCITX {
  enable: () => void
  disable: () => void
  currentInputMethod: () => string
  setCurrentInputMethod: (im: string) => void
  getInputMethods: () => { name: string, displayName: string }[]
  setInputMethods: (ims: string[]) => void
  getAllInputMethods: () => { name: string, displayName: string, languageCode: string }[]
  setStatusAreaCallback: (callback: () => void) => void
  updateStatusArea: () => void
  getConfig: (uri: string) => Config
  setConfig: (uri: string, json: object) => void
  getAddons: () => AddonCategory[]
  jsKeyToFcitxString: (event: KeyboardEvent) => string
  getMenuActions: () => MenuAction[]
  activateMenuAction: (id: number) => void
  installPlugin: (buffer: ArrayBuffer) => string
  getInstalledPlugins: () => string[]
  unzip: (buffer: ArrayBuffer, dir: string) => void
  Module: EM_MODULE
}

export const fcitxReady: Promise<null>
export function loadZip(url: string): Promise<void>
