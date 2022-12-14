-- default desktop configuration for Fedora

import qualified Data.Map as M
import Data.Maybe (maybe)
import Data.Monoid
import System.Exit
import System.Posix.Env (getEnv)
import XMonad
import XMonad.Config.Desktop
import XMonad.Config.Gnome
import XMonad.Config.Kde
import XMonad.Config.Xfce
import XMonad.Hooks.ManageDocks
import XMonad.Layout.LayoutModifier
import XMonad.Layout.NoBorders
import XMonad.Layout.Renamed
import XMonad.Layout.ResizableTile
import XMonad.Layout.Spacing
import qualified XMonad.StackSet as W
import XMonad.Util.Run
import XMonad.Util.SpawnOnce

desktop "gnome" = gnomeConfig
desktop "kde" = kde4Config
desktop "xfce" = xfceConfig
desktop "xmonad-mate" = gnomeConfig
desktop _ = desktopConfig

myTerminal :: String
myTerminal = "alacritty"

-- Whether focus follows the mouse pointer
myFocusFollowsMouse :: Bool
myFocusFollowsMouse = True

-- Whether clicking on a window to focus also passes the click to the window
myClickJustFocuses :: Bool
myClickJustFocuses = False

-- Width of window border in pixels
myBorderWidth :: Dimension
myBorderWidth = 2

-- Set ModMask to super key
-- mod1Mask = left alt
-- mod2Mask =
-- mod3Mask = right alt
-- mod4Mask = super
myModMask = mod4Mask

myWorkspaces = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

-- Border colors for unfocused and focused windows
myNormalBorderColor = "#dddddd"

myFocusedBorderColor = "#0000ff"

-- Keyboard bindings
myKeys conf@XConfig {XMonad.modMask = modm} =
  M.fromList $
    -- Terminal
    [ ((modm, xK_Return), spawn $ XMonad.terminal conf),
      -- dmenu
      ((modm .|. shiftMask, xK_y), spawn "dmenu_run"),
      -- rofi
      ((modm, xK_y), spawn "rofi -show drun"),
      -- flameshot
      ((modm .|. shiftMask, xK_s), spawn "flameshot gui"),
      -- thunar
      ((modm, xK_e), spawn "thunar"),
      -- Close focused window
      ((modm, xK_q), kill),
      -- Rotate through the available layout algorithms
      ((modm, xK_space), sendMessage NextLayout),
      -- Reset the layouts on the current workspace to default
      ((modm .|. shiftMask, xK_space), setLayout $ XMonad.layoutHook conf),
      -- Resize viewed windows to the correct size
      ((modm, xK_n), refresh),
      -- Move focus to the next window
      ((modm, xK_j), windows W.focusDown),
      -- Move focus to the previous window
      ((modm, xK_k), windows W.focusUp),
      -- Move focus to the master window
      ((modm, xK_m), windows W.focusMaster),
      -- Swap the focused window and the master window
      ((modm .|. shiftMask, xK_Return), windows W.swapMaster),
      -- Swap the focused window with the next window
      ((modm .|. shiftMask, xK_j), windows W.swapDown),
      -- Swap the focused window with the previous window
      ((modm .|. shiftMask, xK_k), windows W.swapUp),
      -- Shrink the master area
      ((modm, xK_h), sendMessage Shrink),
      -- Expand the master area
      ((modm, xK_l), sendMessage Expand),
      -- Push window back into tiling
      ((modm, xK_t), withFocused $ windows . W.sink),
      -- Increment the number of windows in the master area
      ((modm, xK_comma), sendMessage (IncMasterN 1)),
      -- Decrement the number of windows in the master area
      ((modm, xK_period), sendMessage (IncMasterN (-1))),
      -- Quit xmonad
      ((modm .|. shiftMask, xK_F4), io exitSuccess),
      -- Restart xmonad
      ((modm, xK_F4), spawn "xmonad --recompile; xmonad --restart")
      -- Run xmessage with a summary of the default keybindings (useful for beginners)
      -- ((modm .|. shiftMask, xK_slash), spawn ("echo \"" ++ help ++ "\" | xmessage -file -"))
    ]
      ++
      -- mod-[1..9], Switch to workspace N
      -- mod-shift-[1..9], Move client to workspace N
      [ ((m .|. modm, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9],
          (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]
      ]

-- ++
-- mod-{w,e,r}, Switch to physical/Xinerama screens 1, 2, or 3
-- mod-shift-{w,e,r}, Move client to screen 1, 2, or 3
-- [ ((m .|. modm, key), screenWorkspace sc >>= flip whenJust (windows . f))
--   | (key, sc) <- zip [xK_w, xK_e, xK_r] [0 ..],
--     (f, m) <- [(W.view, 0), (W.shift, shiftMask)]
-- ]

-- Mouse bindings
myMouseBindings XConfig {XMonad.modMask = modm} =
  M.fromList $
    -- mod-button1, Set the window to floating mode and move by dragging
    [ ( (modm, button1),
        ( \w ->
            focus w >> mouseMoveWindow w
              >> windows W.shiftMaster
        )
      ),
      -- mod-button2, Raise the window to the top of the stack
      ((modm, button2), (\w -> focus w >> windows W.shiftMaster)),
      -- mod-button3, Set the window to floating mode and resize by dragging
      ( (modm, button3),
        ( \w ->
            focus w >> mouseResizeWindow w
              >> windows W.shiftMaster
        )
      )
      -- you may also bind events to the mouse scroll wheel (button4 and button5)
    ]

-- Layouts
myLayout = avoidStruts (tiled ||| Mirror tiled ||| Full)
  where
    -- default tiling algorithm partitions the screen into two panes
    tiled = spacing 5 $ Tall nmaster delta ratio

    -- The default number of windows in the master pane
    nmaster = 1

    -- Default proportion of screen occupied by master pane
    ratio = 1 / 2

    -- Percent of screen to increment by when resizing panes
    delta = 3 / 100

-- Window rules
myManageHook =
  composeAll
    [ className =? "Gimp" --> doFloat,
      resource =? "desktop_window" --> doIgnore,
      resource =? "kdesktop" --> doIgnore
    ]

-- Event handling
myEventHook = mempty

-- Status bars and logging
myLogHook = return ()

-- Startup hook
myStartupHook = do
  spawnOnce "nitrogen --restore &"
  spawnOnce "picom &"
  spawnOnce "xmobar &"
  spawnOnce "gnome-keyring-daemon -s"

main = do
  xmonad $ docks defaults
  xmproc <- spawnPipe "xmobar -x 0 /home/adamekka/.config/xmobar/xmobar.hs"
  session <- getEnv "DESKTOP_SESSION"
  xmonad $ maybe desktopConfig desktop session

defaults =
  def
    { -- simple stuff
      terminal = myTerminal,
      focusFollowsMouse = myFocusFollowsMouse,
      clickJustFocuses = myClickJustFocuses,
      borderWidth = myBorderWidth,
      modMask = myModMask,
      workspaces = myWorkspaces,
      normalBorderColor = myNormalBorderColor,
      focusedBorderColor = myFocusedBorderColor,
      -- key bindings
      keys = myKeys,
      mouseBindings = myMouseBindings,
      -- hooks, layouts
      layoutHook = myLayout,
      manageHook = myManageHook,
      handleEventHook = myEventHook,
      logHook = myLogHook,
      startupHook = myStartupHook
    }
