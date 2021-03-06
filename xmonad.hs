{-# Language OverloadedStrings #-}
import XMonad
import System.Exit
import qualified XMonad.StackSet as W
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.SetWMName
import XMonad.Util.Run (spawnPipe)
import Graphics.X11.ExtraTypes.XF86
import XMonad.Layout.NoBorders
import XMonad.Layout.Fullscreen
import XMonad.Layout.Tabbed
import XMonad.Layout.PerWorkspace

import Text.Regex.PCRE.Light
import Data.ByteString.Internal (packChars, unpackChars)

import System.IO (hPutStrLn)
import qualified Data.Map as M
import qualified Data.Monoid

main :: IO ()
main = do
  xmproc <- spawnPipe "/home/berdes/.cabal/bin/xmobar /home/berdes/.xmobarrc"
  xmonad $ def {
      terminal = myTerminal,
      modMask = myModKey,
      workspaces = myWorkspaces,
      keys = myKeys,
      layoutHook = myLayoutHook,
      manageHook = manageDocks <+> myManagementHooks <+> manageHook def,
      handleEventHook = docksEventHook <+> handleEventHook def,
      logHook = dynamicLogWithPP xmobarPP {
          ppOutput = hPutStrLn xmproc,
          ppTitle = xmobarColor "green" "" . shorten 50
        },
      startupHook = myStartupHook
    }

myLayoutHook =
  onWorkspace "1" (lt ||| lfs) $
    ln ||| lfs ||| lt
  where lt = (avoidStruts . noBorders $ simpleTabbed)
        lfs = noBorders (fullscreenFull Full)
        ln = (avoidStruts . smartBorders $ Tall 1 (3/100) (1/2))

myModKey :: KeyMask
myModKey = mod4Mask

myWorkspaces :: [String]
myWorkspaces = map show [1..9]

myWorkspacesKey :: [KeySym]
myWorkspacesKey = [
    xK_quotedbl,
    xK_guillemotleft,
    xK_guillemotright,
    xK_parenleft,
    xK_parenright,
    xK_at,
    xK_plus,
    xK_minus,
    xK_slash
  ]

myTerminal :: String
myTerminal = "terminator"

spawnLocatedTerm :: String -> X ()
spawnLocatedTerm term = do
  ws <- gets windowset
  case W.stack . W.workspace $ W.current ws of
    Just s  -> do
      t <- runQuery title $ W.focus s
      case match (compile "^[^ ]+  (.+)$" []) (packChars t) [] of
        Just [_, dir] -> spawn $ term ++ " --working-dir " ++ unpackChars dir
        Nothing ->
          case match (compile "^[^ ]+ [^(]*\\((.+)\\) - VIM$" []) (packChars t) [] of
          Just [_, dir] -> spawn $ term ++ " --working-dir " ++ unpackChars dir
          Nothing -> spawn term
    Nothing -> spawn term

myKeys :: XConfig t -> M.Map (KeyMask, KeySym) (X ())
myKeys conf@(XConfig {modMask = modm}) = M.fromList $ [
    ((modm, xK_Return), spawnLocatedTerm $ terminal conf),
    ((modm, xK_a     ), spawnLocatedTerm $ terminal conf),
    ((modm, xK_n     ), spawn "chromium"),
    ((modm, xK_l     ), spawn "i3lock -i ~/.xmonad/arch.png"),
    ((modm, xK_d     ), spawn "dmenu_run -b"),
    ((0, xF86XK_AudioLowerVolume), spawn "amixer set Master 2%-"),
    ((0, xF86XK_AudioRaiseVolume), spawn "amixer set Master 2%+"),
    ((0, xF86XK_AudioMute), spawn "amixer set Master toggle"),
    ((modm, xK_y     ), spawn "bash -c \"synclient TouchpadOff=$(synclient -l | grep -c 'TouchpadOff.*=.*0')\""),
    ((modm, xK_t     ), windows W.focusDown),
    ((modm, xK_s     ), windows W.swapMaster),
    ((modm, xK_c     ), sendMessage Shrink),
    ((modm, xK_r     ), sendMessage Expand),
    ((modm, xK_space ), sendMessage NextLayout),
    ((modm, xK_u     ), withFocused $ windows . W.sink),
    ((modm, xK_q     ), kill),
    ((modm .|. shiftMask, xK_q), io (exitWith ExitSuccess)),
    ((modm .|. shiftMask, xK_r), spawn "xmonad --recompile; xmonad --restart")
  ]
  ++
  [
    ((modm .|. m, k), windows $ f i)
      | (i, k) <- zip (workspaces conf) myWorkspacesKey
      , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]
  ]

myManagementHooks :: Query (Data.Monoid.Endo WindowSet)
myManagementHooks = composeAll [
    resource =? "stalonetray" --> doIgnore,
    title =? "/usr/bin/mcabber" --> doShift "1"
  ]

myStartupHook :: X ()
myStartupHook = do
  spawn "terminator -x mcabber"
  spawn "feh --bg-scale .xmonad/arch.png"
  setWMName "LG3D"
