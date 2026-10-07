# View Development Guide

This guide explains how to create Views in this Roblox MVC project.

## What is a View?

Views are client-side scripts that handle visual feedback, audio, and user interactions. There are two types:

- **HUD views** (ScreenGui/UI): React-luau components that render 2D interface elements. Built as ModuleScripts (`.luau`) and composed inside `HudApp.client.luau`, which mounts a single ScreenGui via ReactRoblox.
- **Workspace views** (3D parts/models): Imperative LocalScripts (`.client.luau`) that use CollectionService to find tagged instances in the 3D world and wire up interactions, tweens, and particle effects.

Both types observe game state and provide immediate user feedback while the server remains the authority for state changes.

## Architecture Overview

### HUD Views (React-Luau)

HUD views are React function components. A single entry point (`HudApp.client.luau`) mounts one ScreenGui into PlayerGui. All HUD state flows through React:

- **State**: `useBoltState` hook bridges Bolt RemoteProperty into React state
- **Data flow**: Props flow down from HudApp to child components
- **Modal coordination**: `activeModal` React state in HudApp (only one modal visible at a time)
- **View-to-view communication**: React props and callbacks (no BindableEvents)

### Workspace Views (Imperative)

Workspace views are standalone LocalScripts. Each script uses CollectionService to find tagged 3D instances and set up interactions directly:

- **State**: `Network.State.*:Observe()` callbacks update local variables
- **Interactions**: ProximityPrompts, tweens, particle emitters
- **Data flow**: Each script manages its own state and connections

## View Patterns

Views follow one of three patterns (or a combination). The decision tree applies to both HUD and workspace views.

### Pattern A: Pure Client-Side Feedback
- No server communication
- Immediate visual/audio response only
- Example: Particle effects, sound effects, camera shake, tween animations

### Pattern B: Intent-Based with Server Validation
- Send intent to Controller via Bolt ReliableEvent (`Network.Intent.*`)
- Provide immediate feedback (particles, sounds)
- Wait for server confirmation before showing final state
- Examples:
  - **Workspace**: CashMachineView (ProximityPrompt triggers withdraw intent)
  - **Workspace**: ShrineView (ProximityPrompt triggers donate intent)

### Pattern C: State Observation and UI Updates
- Observe Model state changes via Bolt RemoteProperty (`Network.State.*:Observe()`)
- Update display based on authoritative server state
- `Observe()` fires immediately with current state, then on every update
- Bolt handles per-player filtering automatically for User-scoped models
- Examples:
  - **HUD**: StatusBarView (receives gold/treasure as props from HudApp, which observes Inventory state)
  - **HUD**: FavoursView (receives favoursData as props from HudApp, which observes Favours state)
  - **Workspace**: CandleView (observes Candles state, spawns/removes 3D models)

### Pattern B + C: Combination
- User actions (Pattern B) plus state observation (Pattern C) in the same feature
- Examples:
  - **Workspace**: BazaarView (ProximityPrompt sends buy intent + observes gold to toggle availability)
  - **Workspace**: ShrineView (ProximityPrompt sends donate intent + observes inventory and shrine state)

### Decision Tree

```
Does view need server communication?
+-- No --> Pattern A (Pure Client)
+-- Yes --> Does view send user actions?
    +-- No --> Pattern C (State Observation)
    +-- Yes --> Does view also observe state?
        +-- No --> Pattern B (Intent-Based)
        +-- Yes --> Pattern B + C (Combination)
```

### Common Mistakes

- **Using Pattern A for game state changes** -- Do not update UI based on client predictions alone. Always wait for server confirmation for authoritative state.
- **Using Pattern B without considering state updates** -- If your view displays changing data, you likely need Pattern C too. Separate concerns: interaction (B) + display (C).
- **Not filtering ownerId for "all" scope broadcasts** -- Server-scoped models broadcast to all players. Views must filter to show only relevant data when needed.

## React-Luau HUD Architecture

### File Structure

```
Source/ReplicatedFirst/views/
+-- HudApp.client.luau          -- Entry point, mounts React tree into PlayerGui
+-- StatusBarView.luau           -- Always-visible status bar component
+-- FavoursView.luau             -- Favours modal body content
+-- CandlesView.luau             -- Candles modal body content
+-- components/                  -- Shared building blocks
|   +-- CurrencyChip.luau       -- Gold/treasure display chip
|   +-- HudButton.luau          -- Toggle button with active state
|   +-- ModalWindow.luau        -- Reusable modal window frame
|   +-- FavourTile.luau         -- Individual favour card
+-- hooks/
    +-- useBoltState.luau        -- Bolt RemoteProperty --> React state bridge
```

### Skin kit (Ripple Avatar Creator)

The project's visual language lives in a small kit, built in Task 1 of
`features/cac-adaptation/PLAN.md` from the Claude Design mock in
`features/cac-adaptation/design/`. New HUD work should compose these rather than
restyling from scratch:

```
Source/ReplicatedFirst/views/
+-- Tokens.luau                  -- every colour, gradient, radius, size, type style, spring preset
+-- SkinAssets.luau              -- the one module holding image asset IDs (icons)
+-- SkinContext.luau             -- sizing mode, glass mode, scale (provided by SkinRoot)
+-- components/
|   +-- SkinRoot.luau            -- viewport root; owns the sizing decision; provides SkinContext
|   +-- PillButton.luau          -- glossy round/pill button: hover glow, 0.94 press, active orange
|   +-- PillTabs.luau            -- segmented top tab bar
|   +-- GlossFace.luau           -- the black/orange split-gradient fill both of the above use
|   +-- GlassPanel.luau          -- dark / bar / light glass surfaces
|   +-- Badge.luau               -- count badge (Robux) and marker badges (wearing / in basket)
|   +-- TextTab.luau             -- underlined text tab
|   +-- Chip.luau                -- outlined filter chip
|   +-- Icon.luau                -- Material Symbols Rounded glyph (one image per icon)
+-- hooks/
|   +-- useSkin.luau             -- px / stroke / textPx / fromScreen for the current sizing mode
|   +-- useInteraction.luau      -- hover + press state (touch-safe)
|   +-- useGlassBlur.luau        -- client-only scene blur behind full-screen panels
|   +-- useSystemBarInset.luau   -- real-pixel area of Roblox's top-bar buttons
+-- gallery/                     -- TEMPORARY Task 1 HUD mock, mounted by HudApp until Task 2's shell
```

- **Design pixels everywhere.** Components take the design's own px values
  (1180×820 canvas) and convert through `useSkin().px`, so the
  relative-vs-canvas sizing decision lives only in `SkinRoot`.
- **Fonts:** Nunito ships with Roblox: `Tokens.font(weight)` maps design weights
  600/700/800/900 to `Enum.FontWeight` SemiBold/Bold/ExtraBold/Heavy.
- **Icons:** one white 128px PNG per Material Symbols Rounded glyph
  (`assets/ui/icons/`, rebuilt by `tools/build_icons.py`), tinted with
  `ImageColor3`. Image asset IDs live in `SkinAssets`; an icon with no ID draws
  a deliberate placeholder.
- **No `AutomaticSize` for text under a `SkinRoot` canvas.** Under an ancestor
  `UIScale`, Roblox auto-sizes text from its on-screen bounds, so anything that
  auto-sizes after the scale is applied comes out scale× too wide (it shifted
  the tab labels in a freshly opened panel). Size text explicitly with
  `hooks/useTextWidth` — `ShadowText`, `TextTab`, `Chip` and `Badge` already do.
- **Gradients:** always on a white `BackgroundColor3` (pitfall 1). Gradient
  colours can't be sprung, so "active" crossfades a second face's
  transparency.
- **Roblox's top bar** is fixed-size in real pixels: lay out against
  `useSystemBarInset()` converted with `useSkin().fromScreen`, never a scaled
  design-px guess.

### HudApp.client.luau -- Entry Point

HudApp is the single LocalScript that mounts the entire HUD. It:

1. Subscribes to Bolt state via `useBoltState`
2. Holds the `activeModal` state for modal coordination
3. Passes data and callbacks down to child components as props
4. Renders one ScreenGui containing all HUD elements

```lua
local function HudApp()
    local activeModal, setActiveModal = React.useState(nil :: string?)

    -- Subscribe to server state via useBoltState
    local inventory = useBoltState(Network.State.Inventory, INVENTORY_DEFAULT)
    local favoursDict = useBoltState(Network.State.Favours, FAVOURS_DEFAULT)

    local toggleModal = React.useCallback(function(modalName: string)
        setActiveModal(function(current: string?)
            if current == modalName then
                return nil
            end
            return modalName
        end)
    end, {})

    local closeModal = React.useCallback(function()
        setActiveModal(nil)
    end, {})

    return e("ScreenGui", {
        Name = "HudApp",
        DisplayOrder = 100,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, {
        StatusBar = e(StatusBarView, {
            gold = inventory.gold,
            treasure = inventory.treasure,
            activeModal = activeModal,
            onToggleModal = toggleModal,
        }),
        Modal = modalElement, -- built from activeModal state
    })
end

-- Mount into PlayerGui
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local root = ReactRoblox.createRoot(playerGui)
root:render(e(HudApp))
```

### useBoltState Hook

`useBoltState` bridges Bolt RemoteProperty into React. It calls `Observe()`, which fires immediately with the current value and then on every update. The hook returns the current state value and triggers a React re-render on changes.

```lua
-- API: useBoltState(remoteProperty, initialValue) -> currentValue
local inventory = useBoltState(Network.State.Inventory, {
    ownerId = "",
    gold = 0,
    treasure = 0,
    favourIds = {},
})
```

Implementation (`Source/ReplicatedFirst/views/hooks/useBoltState.luau`):

```lua
local function useBoltState<T>(remoteProperty: any, initialValue: T): T
    local state, setState = React.useState(initialValue)

    React.useEffect(function()
        local unsubscribe = remoteProperty:Observe(function(newValue: T)
            setState(newValue)
        end)

        return function()
            if type(unsubscribe) == "function" then
                unsubscribe()
            end
        end
    end, {})

    return state
end
```

Key points:
- Pass the Bolt `RemoteProperty` and a default value matching the state shape
- Returns the latest state value; React re-renders the component when it changes
- The `useEffect` cleanup function unsubscribes when the component unmounts
- No manual initial state request needed -- `Observe()` fires immediately

### Props Pattern

HudApp subscribes to server state and passes data down as props. Child components are pure renderers that receive their data through props:

```lua
-- HudApp passes inventory data and callbacks to StatusBarView
StatusBar = e(StatusBarView, {
    gold = inventory.gold,
    treasure = inventory.treasure,
    activeModal = activeModal,
    onToggleModal = toggleModal,
})

-- StatusBarView declares its props type
export type Props = {
    gold: number,
    treasure: number,
    activeModal: string?,
    onToggleModal: (string) -> (),
}
```

### Modal Management

Modals are coordinated via `activeModal` state in HudApp. Only one modal can be open at a time:

- `activeModal = nil` -- no modal visible
- `activeModal = "favours"` -- Favours modal visible
- `activeModal = "candles"` -- Candles modal visible

Toggling is handled by `toggleModal`, which sets `activeModal` to the modal name or `nil` if it is already active. The `closeModal` callback sets `activeModal` to `nil`.

The shared `ModalWindow` component (`components/ModalWindow.luau`) provides the frame, title bar, currency display, and close button. Modal body content is passed in via the `bodyContent` prop:

```lua
if activeModal == "favours" then
    modalElement = e(ModalWindow, {
        title = "Favours",
        subtitle = `{favourCount} \u{00B7} BLESSINGS EARNED AT THE SHRINE`,
        gold = inventory.gold,
        treasure = inventory.treasure,
        onClose = closeModal,
        bodyContent = e(FavoursView, {
            favoursData = favoursDict,
        }),
    })
end
```

## Animation

The project includes a spring physics animation system built on React bindings. Animations run on `RenderStepped` and update Instance properties directly — no re-renders during motion.

### Spring Physics Config (SpringSolver.luau)

SpringSolver is a pure math module (no React dependency) implementing a damped harmonic oscillator. It decomposes complex types (UDim2, Color3, Vector2) into number arrays, solves component-wise, then recomposes.

Config parameters:
- `force` — stiffness; how aggressively the spring moves toward the target
- `dampening` — friction; how quickly oscillation settles
- `mass` — inertia; higher values make the spring feel heavier

Default config: `{ force = 180, dampening = 20, mass = 1 }`

**Presets:**

| Use case | force | dampening | mass | Character |
|----------|-------|-----------|------|-----------|
| Modal open/close | 200 | 14 | 1 | Bouncy entrance |
| Modal leave | 300 | 30 | 1 | Fast overdamped exit |
| Tile stagger | 220 | 22 | 1 | Quick pop-in |
| Number tick | 120 | 24 | 1 | Smooth counting, no overshoot |
| Drag spring-back | 300 | 25 | 1 | Stiff physical return |

### useSpring (useSpring.luau)

Binding-based property animation. Animates a dictionary of properties toward target values. Returns React bindings that update Instance properties directly — zero re-renders during animation.

```lua
local springProps = useSpring({
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundTransparency = 0,
}, { force = 200, dampening = 20 })
-- springProps.Position and springProps.BackgroundTransparency are bindings
```

Pass `immediate = true` in the config to snap to target without animating.

### useSpringNumber (useSpringNumber.luau)

Animates a single number using spring physics. Returns a rounded integer via `useState` — re-renders only when the displayed digit changes. Used for currency displays and counters.

```lua
local displayAmount = useSpringNumber(props.amount, { force = 120, dampening = 24 })
```

### useTransition (useTransition.luau)

Enter/leave transitions with stagger. Manages delayed unmount so leaving elements animate out before removal.

**Boolean mode** (single item show/hide — modals):

```lua
local transitions = useTransition(isVisible, {
    from = { BackgroundTransparency = 1, WindowYOffset = -50 },
    enter = { BackgroundTransparency = 0, WindowYOffset = 0 },
    leave = { BackgroundTransparency = 1, WindowYOffset = -50 },
    config = { force = 200, dampening = 14 },
    leaveConfig = { force = 300, dampening = 30 },
})
```

**List mode** (multiple items with stagger — grids):

```lua
local transitions = useTransition(items, {
    from = { BackgroundTransparency = 1 },
    enter = { BackgroundTransparency = 0 },
    leave = { BackgroundTransparency = 1 },
    trail = 40, -- ms between items
    keys = function(item) return item.id end,
    config = { force = 220, dampening = 22 },
})
```

Returns an array of `{ item, key, springProps, phase }`. Each `springProps` table contains bindings. `phase` is `"entering"`, `"entered"`, or `"leaving"`.

Separate `leaveConfig` allows fast overdamped exits while keeping bouncy entrances. `AnimatedModal` (`components/AnimatedModal.luau`) wraps this for the modal use case.

### useDrag (useDrag.luau)

Drag with momentum and spring-back. Tracks release velocity from a circular buffer of position samples and feeds it into the spring as initial velocity.

```lua
local dragBind, dragOffset = useDrag({ springBack = true, config = { force = 300, dampening = 25 } })
-- Bind: [React.Event.InputBegan] = dragBind.onInputBegan
-- Position: dragOffset:map(function(offset) return UDim2.new(0.5, offset.X, 0.5, offset.Y) end)
```

### CanvasGroup Pattern

Use `CanvasGroup` instead of `Frame` when you need `GroupTransparency` for uniform fade (e.g., fading an entire modal including all children).

Gotcha: `UIStroke` on a `CanvasGroup` does NOT fade with `GroupTransparency`. Put the stroke on a child `Frame` inside the `CanvasGroup` instead.

### File Locations

```
views/hooks/
  SpringSolver.luau      — Pure math, no React dependency
  useSpring.luau          — Binding-based property springs
  useSpringNumber.luau    — Number springs for text displays
  useTransition.luau      — Enter/leave/stagger transitions
  useDrag.luau            — Drag with momentum + spring-back
  useViewportScale.luau   — Viewport-height scale factor for residual pixels
views/components/
  AnimatedModal.luau      — Delayed-unmount modal wrapper using useTransition
```

## Responsive Scaling

Roblox games render on every aspect ratio from phone portrait to ultrawide PC. HUD views must **scale relatively**, not to fixed pixels. The mental model: an energy bar is "40% of the screen width" (`UDim2.fromScale(0.4, ...)`) at every resolution — never "268 px wide", which is huge on a phone and tiny on a 4K monitor.

**Default to `UDim2.fromScale`.** Size and position elements as fractions of their parent. Reserve `UDim2.fromOffset` (fixed pixels) for genuinely fixed things (a 1 px divider, an icon that must not scale) — and even then, prefer scaling the pixel value (see `useViewportScale` below).

**Fixed pixels everywhere is a code smell.** If a design hands you `width: 268px; top: 30px; font-size: 38px` with no `vh`/`vw`/`aspect-ratio`, that layout will break for most players. Convert it to relative sizing rather than translating `px` 1:1 to `fromOffset`. (The `/html-to-react-luau` skill's Phase 2a walks through exactly this.)

**Lock shapes with `UIAspectRatioConstraint`.** When an element must keep its proportions (a square avatar, a hex badge), give it a positive `Size` on both axes and add a `UIAspectRatioConstraint`. Note the trap: `Size = UDim2.fromScale(0, 1)` collapses to nothing — both axes need positive Scale (see the skill's pitfall #10).

**Residual pixels → `useViewportScale`.** A few things can't be a Scale UDim — `UIStroke.Thickness`, small `UICorner` radii, and `TextSize` derived from a `vh` design value. `useViewportScale()` returns `viewport.Y / 1080`; multiply your design-pixel value by it so those pixels stay proportional to the rest of the layout:

```lua
local useViewportScale = require(script.Parent:WaitForChild("hooks"):WaitForChild("useViewportScale"))

local function Badge()
    local scale = useViewportScale()
    return e("Frame", {
        Size = UDim2.fromScale(0.2, 0.1),
        BackgroundColor3 = Color3.new(1, 1, 1),
    }, {
        Corner = e("UICorner", { CornerRadius = UDim.new(0, math.floor(12 * scale + 0.5)) }),
        Stroke = e("UIStroke", { Thickness = math.max(1, math.floor(3 * scale + 0.5)) }),
        Label = e("TextLabel", {
            -- CSS `font-size: 4vh` → 4% of a 1080 design height, scaled to viewport
            TextSize = math.max(10, math.floor(0.04 * 1080 * scale + 0.5)),
        }),
    })
end
```

**Caveat — `useViewportScale` is height-axis only.** It tracks viewport *height*, so it stays proportional only for elements that also scale with height (e.g. corner-pinned pieces in a viewport-filling root). It is **wrong** for pixels inside an aspect-locked, width-dominant container (a centred modal with `UIAspectRatioConstraint` + `DominantAxis.Width`) — there, drive scale off the container's own measured `AbsoluteSize`. The `/html-to-react-luau` skill (pitfalls #12–13) has the full treatment, including the "Canvas + `UIScale`" pattern for fixed-pixel modals.

**Prefer computed `TextSize` over `TextScaled` for `vh`-based fonts.** `TextScaled` fills the label's container (layout-dependent); a `vh` font size is a literal viewport fraction. Compute `TextSize` from `useViewportScale` as above. Use `TextScaled` only when text lives inside a uniformly scaled fixed-pixel canvas.

> **Ripple Avatar Creator sizing decision: `fill`, scaled by height.** HUD content is authored in design pixels on the 1180×820 canvas inside `SkinRoot`, which applies one `UIScale` (viewport height ÷ 820) to a canvas stretched to the screen's aspect, so corner-pinned pieces reach the real edges. Chosen over `relative` (per-element pixels) and `fit` (letterboxed) after testing in Task 1. Under this mode: don't use `AutomaticSize` for text (see Skin kit), and convert real-pixel measurements (Roblox's top bar) with `useSkin().fromScreen`. Glass decision: scene blur behind full-screen panels.

> **Starting from a design?** Run `/html-to-react-luau` to translate an HTML/CSS/JSX mockup (or screenshot) into a react-luau component that follows these rules, then wire its state with `/create-view`.

## Creating a HUD View

### Step 1: Create the Component

Create a new ModuleScript in `Source/ReplicatedFirst/views/YourView.luau`:

```lua
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local e = React.createElement

export type Props = {
    someData: string,
    onAction: () -> (),
}

local function YourView(props: Props)
    return e("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
    }, {
        Label = e("TextLabel", {
            Size = UDim2.new(1, 0, 0, 30),
            Text = props.someData,
            BackgroundTransparency = 1,
            TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.GothamMedium,
            TextSize = 14,
        }),
    })
end

return YourView
```

### Step 2: Add to HudApp

Import the component in `HudApp.client.luau` and add it to the render tree:

```lua
local YourView = require(viewsFolder:WaitForChild("YourView"))

-- Inside HudApp function, add to the ScreenGui children:
YourView = e(YourView, {
    someData = inventory.gold,
    onAction = someCallback,
}),
```

If your view is a modal, wrap it in `ModalWindow` and gate it on `activeModal`:

```lua
elseif activeModal == "yourModal" then
    modalElement = e(ModalWindow, {
        title = "Your Modal",
        onClose = closeModal,
        bodyContent = e(YourView, {
            someData = someData,
        }),
    })
```

### Step 3: Add State (if needed)

If your view needs server state, add a `useBoltState` call in HudApp and pass the data down as props:

```lua
local yourData = useBoltState(Network.State.YourModel, { defaultField = "" })

-- Pass to component
YourView = e(YourView, {
    someData = yourData.defaultField,
}),
```

## Creating a Workspace View

### Step 1: Create the LocalScript

Create a new LocalScript in `Source/ReplicatedFirst/views/YourView.client.luau`:

```lua
--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage:WaitForChild("Network"))

local YOUR_TAG = "YourTag"

local function setupInstance(instance: Instance)
    local base = instance:WaitForChild("Base")
    local proximityPrompt = base:WaitForChild("ProximityPrompt") :: ProximityPrompt
    local sound = base:WaitForChild("Sound") :: Sound

    proximityPrompt.Triggered:Connect(function(player: Player)
        -- Immediate feedback
        sound:Play()

        -- Send intent to server
        Network.Intent.YourFeature:FireServer(Network.Actions.YourFeature.Action, data)
    end)
end

-- Handle existing tagged instances
for _, instance in ipairs(CollectionService:GetTagged(YOUR_TAG)) do
    task.spawn(function()
        setupInstance(instance)
    end)
end

-- Handle dynamically added instances
CollectionService:GetInstanceAddedSignal(YOUR_TAG):Connect(function(instance: Instance)
    task.spawn(function()
        setupInstance(instance)
    end)
end)
```

### Step 2: Tag Instances in Studio

Add the tag to your 3D instances in Roblox Studio using the Tag Editor (View > Tags or Alt+T).

### Step 3: Add State Observation (if needed)

For Pattern C or B+C, add an Observe call inside the setup function:

```lua
Network.State.YourModel:Observe(function(data: Network.YourModelState)
    -- Update visual state based on server data
    updateVisuals(data)
end)
```

## Example: CashMachineView (Workspace, Pattern B)

`Source/ReplicatedFirst/views/CashMachineView.client.luau` -- Intent-based with immediate feedback:

```lua
--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage:WaitForChild("Network"))

local cashMachineIntent = Network.Intent.CashMachine

local CASH_MACHINE_TAG = "CashMachine"
local WITHDRAW_AMOUNT = 50

local function setupCashMachine(cashMachine: Instance)
    local base = cashMachine:WaitForChild("Base")

    local proximityPrompt = base:WaitForChild("ProximityPrompt") :: ProximityPrompt
    local particleEmitter = base:WaitForChild("ParticleEmitter") :: ParticleEmitter
    local sound = base:WaitForChild("Sound") :: Sound

    proximityPrompt.Triggered:Connect(function(player: Player)
        local particleCount = particleEmitter.Rate
        particleEmitter:Emit(particleCount)

        sound:Play()

        cashMachineIntent:FireServer(Network.Actions.CashMachine.Withdraw, WITHDRAW_AMOUNT)
    end)
end

for _, cashMachine in ipairs(CollectionService:GetTagged(CASH_MACHINE_TAG)) do
    task.spawn(function()
        setupCashMachine(cashMachine)
    end)
end

CollectionService:GetInstanceAddedSignal(CASH_MACHINE_TAG):Connect(function(cashMachine: Instance)
    task.spawn(function()
        setupCashMachine(cashMachine)
    end)
end)
```

Key points:
- Uses CollectionService directly to find tagged "CashMachine" instances
- Provides immediate visual/audio feedback (particles + sound)
- Sends intent to server via Bolt ReliableEvent
- Handles both existing and dynamically added instances via `task.spawn`

## Example: StatusBarView (HUD, Pattern C)

`Source/ReplicatedFirst/views/StatusBarView.luau` -- React component receiving state as props:

```lua
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local componentsFolder = script.Parent:WaitForChild("components")
local CurrencyChip = require(componentsFolder:WaitForChild("CurrencyChip"))
local HudButton = require(componentsFolder:WaitForChild("HudButton"))

local e = React.createElement

export type Props = {
    gold: number,
    treasure: number,
    activeModal: string?,
    onToggleModal: (string) -> (),
}

local function StatusBarView(props: Props)
    local onToggleFavours = React.useCallback(function()
        props.onToggleModal("favours")
    end, { props.onToggleModal })

    local onToggleCandles = React.useCallback(function()
        props.onToggleModal("candles")
    end, { props.onToggleModal })

    return e("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 20),
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 0, 44),
        BackgroundColor3 = Color3.fromRGB(18, 20, 24),
        BackgroundTransparency = 0.22,
    }, {
        -- Layout, padding, corner, stroke...
        GoldChip = e(CurrencyChip, {
            currencyType = "gold",
            amount = props.gold,
            layoutOrder = 1,
        }),
        TreasureChip = e(CurrencyChip, {
            currencyType = "treasure",
            amount = props.treasure,
            layoutOrder = 3,
        }),
        FavoursButton = e(HudButton, {
            label = "Favours",
            icon = "\u{2B50}",
            isActive = props.activeModal == "favours",
            onActivated = onToggleFavours,
            layoutOrder = 5,
        }),
        CandlesButton = e(HudButton, {
            label = "Candles",
            icon = "\u{1F56F}",
            isActive = props.activeModal == "candles",
            onActivated = onToggleCandles,
            layoutOrder = 6,
        }),
    })
end

return StatusBarView
```

Key points:
- Pure function component -- receives all data via props, no direct state subscriptions
- `gold` and `treasure` come from HudApp, which observes `Network.State.Inventory` via `useBoltState`
- Modal toggling uses `onToggleModal` callback prop (no BindableEvents)
- Composes shared components: `CurrencyChip`, `HudButton`

## Model Scopes and State Formats

The state format you receive in `Observe()` depends on the model's scope. Entity-scoped models send aggregated dictionaries, not single objects.

### User Scope (e.g., InventoryModel)

One instance per player. Default (`syncScope = "owner"`): state sent only to the owner as a single object.

```lua
-- In a workspace view (direct Observe):
inventoryState:Observe(function(data: Network.InventoryState)
    -- data is a single object: { ownerId, gold, treasure, ... }
    updateLabels(data.gold, data.treasure)
end)

-- In a HUD view (via useBoltState in HudApp):
local inventory = useBoltState(Network.State.Inventory, {
    ownerId = "",
    gold = 0,
    treasure = 0,
    favourIds = {},
})
-- inventory.gold, inventory.treasure available as React state
```

Broadcast variant (`syncScope = "all"`): all users' states aggregated into a dictionary keyed by `ownerId`:

```lua
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

type PowerUpStateDictionary = { [string]: Network.PowerUpState }

powerUpState:Observe(function(allPowerUps: PowerUpStateDictionary)
    -- allPowerUps is { [ownerId] = { ownerId, power, ... } }
    local myState = allPowerUps[tostring(localPlayer.UserId)]
    if myState then
        updatePowerUpDisplay(myState.power)
    end
end)
```

### Server Scope (e.g., ShrineModel)

One instance for the entire server. State broadcast to all players as a single object.

```lua
shrineState:Observe(function(data: Network.ShrineState)
    -- data is a single object: { ownerId = "SERVER", treasure, ... }
    updateShrineDisplay(data.treasure)
end)
```

### UserEntity Scope (e.g., FavoursModel)

Multiple instances per player (one per entity). State sent only to the owner as a dictionary keyed by entityId.

```lua
-- In a workspace view (direct Observe):
type FavoursStateDictionary = { [string]: Network.FavoursState }

favoursState:Observe(function(allFavours: FavoursStateDictionary)
    clearList()
    for entityId, favourData in allFavours do
        addToList(entityId, favourData.favourType)
    end
end)

-- In a HUD view (via useBoltState in HudApp):
local favoursDict = useBoltState(Network.State.Favours, {} :: { [string]: Network.FavoursState })
-- favoursDict is the full dictionary, passed as props to FavoursView
```

### ServerEntity Scope (e.g., CandlesModel)

Multiple instances shared across all players (one per entity). State broadcast to all players as a dictionary keyed by entityId. Must handle both spawning new entities and removing entities no longer in state.

```lua
type CandlesStateDictionary = { [string]: Network.CandlesState }

local spawnedCandles: { [string]: Model } = {}

candlesState:Observe(function(allCandles: CandlesStateDictionary)
    -- Spawn new entities
    for entityId, candleData in allCandles do
        if not spawnedCandles[entityId] then
            spawnCandle(entityId, candleData)
        end
    end

    -- Remove entities no longer in state
    for entityId, model in spawnedCandles do
        if not allCandles[entityId] then
            model:Destroy()
            spawnedCandles[entityId] = nil
        end
    end
end)
```

### Quick Reference Table

| Scope | syncScope | Recipients | State Format | Example |
|-------|-----------|-----------|--------------|---------|
| User | `"owner"` (default) | Owner only | Single object | InventoryModel |
| User | `"all"` (override) | All players | `{ [ownerId]: State }` | PowerUpModel |
| Server | `"all"` (default) | All players | Single object | ShrineModel |
| UserEntity | `"owner"` (default) | Owner only | `{ [entityId]: State }` | FavoursModel |
| ServerEntity | `"all"` (default) | All players | `{ [entityId]: State }` | CandlesModel |

**Common Mistakes with Entity-Scoped Models**:

1. **Treating entity-scoped state as a single object** -- If your Observe callback receives data but nothing happens, check if the model is entity-scoped and iterate the dictionary.

2. **Only handling additions, not removals** -- When entities can be removed (like candles expiring), your view must compare the incoming state with tracked entities and remove any that are no longer present. Either:
   - Clear and rebuild: `clearList()` then iterate (simple but may cause flicker)
   - Diff and update: Spawn new, remove missing (smoother for visual objects)

3. **Treating User + `syncScope="all"` state as a single object** -- If a User-scoped model uses `syncScope = "all"`, its property holds `{ [ownerId]: State }` -- a dictionary keyed by ownerId, broadcast to all players. Index by the local player's UserId to get your own state.

## File Locations

- **HUD entry point**: `Source/ReplicatedFirst/views/HudApp.client.luau`
- **HUD components**: `Source/ReplicatedFirst/views/StatusBarView.luau`, `FavoursView.luau`, `CandlesView.luau`
- **Shared UI components**: `Source/ReplicatedFirst/views/components/`
- **React hooks**: `Source/ReplicatedFirst/views/hooks/`
- **Workspace views**: `Source/ReplicatedFirst/views/*.client.luau` (BazaarView, CandleView, CashMachineView, ShrineView)
- **Network module**: `ReplicatedStorage/Network.luau`

The naming convention distinguishes the two types:
- `.client.luau` -- LocalScript (workspace view or HudApp entry point)
- `.luau` -- ModuleScript (React component or hook)

## Best Practices

### 1. Keep Components Small

Split HUD views into focused components. Use the `components/` folder for shared building blocks (CurrencyChip, HudButton, ModalWindow). Each component should do one thing.

### 2. Use Hooks for State

Use `useBoltState` to subscribe to server state in HudApp. Do not call `Observe()` directly inside React components -- let HudApp manage subscriptions and pass data down as props.

### 3. Props for Data Flow

Pass data and callbacks as props from HudApp to child components. This keeps components pure and testable:

```lua
-- Good: component receives data as props
local function StatusBarView(props: Props)
    return e(CurrencyChip, { amount = props.gold })
end

-- Bad: component subscribes to state directly
local function StatusBarView()
    local inventory = useBoltState(Network.State.Inventory, default)
    return e(CurrencyChip, { amount = inventory.gold })
end
```

Centralizing subscriptions in HudApp avoids duplicate Observe subscriptions and makes state flow easy to trace.

### 4. Use WaitForChild in Workspace Views

Always wait for children to exist in workspace views, as they may not be ready immediately:

```lua
local button = instance:WaitForChild("Button")
local sound = button:WaitForChild("Sound")
```

### 5. Type Safety

Use `--!strict` and type your variables:

```lua
local proximityPrompt = base:WaitForChild("ProximityPrompt") :: ProximityPrompt
local sound = base:WaitForChild("Sound") :: Sound
```

For React components, export a `Props` type:

```lua
export type Props = {
    gold: number,
    treasure: number,
    activeModal: string?,
    onToggleModal: (string) -> (),
}
```

### 6. Immediate Feedback

Provide instant visual feedback before server confirmation (applies to both view types):

```lua
-- Workspace view: particles and sound
proximityPrompt.Triggered:Connect(function(player: Player)
    particleEmitter:Emit(particleEmitter.Rate)
    sound:Play()
    intent:FireServer(Network.Actions.Feature.Action, data)
end)
```

### 7. Handle CollectionService Correctly in Workspace Views

Always handle both existing and dynamically added tagged instances:

```lua
for _, instance in ipairs(CollectionService:GetTagged(TAG)) do
    task.spawn(function()
        setupInstance(instance)
    end)
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(function(instance: Instance)
    task.spawn(function()
        setupInstance(instance)
    end)
end)
```

Use `task.spawn` to avoid one failing setup blocking the rest.

## Relationship to Models and Controllers

### Views --> Controllers
- Views send intents to controllers via Bolt ReliableEvents (`Network.Intent.*:FireServer()`)
- Views never directly modify Models

### Views <-- Models
- Views observe state changes broadcast by Models via Bolt RemoteProperty (`Network.State.*:Observe()`)
- HUD views receive this data as React props (HudApp calls `useBoltState`, passes data down)
- Workspace views call `Observe()` directly in their setup functions

### Complete Flow Example

```
1. User clicks button (View provides immediate feedback)
2. View fires intent: Network.Intent.CashMachine:FireServer(Network.Actions.CashMachine.Withdraw, 50)
3. Controller validates and updates Model
4. Model broadcasts state change to clients via Bolt RemoteProperty
5. HUD: useBoltState triggers React re-render with new state
   Workspace: Observe() callback fires with new state
6. View updates display with authoritative server state
```

## Next Steps

After creating your view:

1. **Create a Controller** (`Source/ServerScriptService/controllers/`) if server validation is needed
2. **Create a Model** (`Source/ServerScriptService/models/`) to store authoritative state
3. **Test the flow** end-to-end with user interactions

See the main [README.md](../README.md) for the complete MVC architecture overview.
