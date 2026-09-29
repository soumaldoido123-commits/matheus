// Gera um subconjunto das definicoes da API do Roblox (globalTypes.d.luau do luau-lsp).
// O arquivo completo estoura o limite de complexidade do analisador em WASM, entao
// mantemos so as classes que o jogo usa (+ vizinhas de 1 nivel) e trocamos o resto por stubs.
import { readFileSync, writeFileSync } from "node:fs";

export function makeDefs(inPath, outPath) {
  const lines = readFileSync(inPath, "utf8").split("\n");
  const starts = [];
  lines.forEach((l, i) => {
    if (/^(declare |type |export type |@\[)/.test(l)) {
      // atributo "@[...]" cola na declaracao seguinte
      if (/^@\[/.test(l) && starts.length && /^@\[/.test(lines[starts[starts.length - 1]])) return;
      if (/^(declare |type |export type )/.test(l) && i > 0 && /^@\[/.test(lines[i - 1])) return;
      starts.push(i);
    }
  });
  const blocks = starts.map((s, n) => {
    const e = n + 1 < starts.length ? starts[n + 1] : lines.length;
    const text = lines.slice(s, e).join("\n");
    const head = lines.slice(s, Math.min(e, s + 3)).join("\n");
    let m;
    let kind = "other";
    let name = null;
    let parent = null;
    if ((m = head.match(/declare extern type (\w+)(?: extends (\w+))? with/))) {
      kind = "class"; name = m[1]; parent = m[2] || null;
    } else if ((m = head.match(/^\s*(?:export )?type (\w+)/m)) && !/declare extern/.test(head.split("\n").find(l=>/type/.test(l)) || "")) {
      kind = "alias"; name = m[1];
    }
    return { text, kind, name, parent };
  });

  const classes = new Map();
  const aliases = new Map();
  for (const b of blocks) {
    if (b.kind === "class") classes.set(b.name, b);
    else if (b.kind === "alias") aliases.set(b.name, b);
  }

  const roots = `Vector3 Vector2 CFrame Color3 UDim UDim2 Random TweenInfo Ray Region3 Rect NumberRange NumberSequence ColorSequence NumberSequenceKeypoint ColorSequenceKeypoint RaycastParams OverlapParams PhysicalProperties BrickColor Font Axes Faces DateTime Vector3int16 RBXScriptSignal RBXScriptConnection Instance PVInstance BasePart Part WedgePart CornerWedgePart TrussPart MeshPart UnionOperation NegateOperation PartOperation Model Folder Humanoid HumanoidDescription Player Players Workspace Terrain Camera Lighting Sky Atmosphere BloomEffect ColorCorrectionEffect SunRaysEffect DepthOfFieldEffect BlurEffect Clouds Sound SoundGroup SoundService ReplicatedStorage ServerScriptService ServerStorage StarterGui StarterPack StarterPlayer StarterPlayerScripts StarterCharacterScripts RunService UserInputService ContextActionService TweenService Debris CollectionService PhysicsService PathfindingService DataStoreService DataStore GlobalDataStore OrderedDataStore DataStorePages MarketplaceService TextService GuiService HttpService TeleportService Attachment Beam Trail ParticleEmitter PointLight SpotLight SurfaceLight Light Fire Smoke Sparkles Explosion WeldConstraint Weld Motor6D JointInstance AlignPosition AlignOrientation VectorForce LinearVelocity AngularVelocity BallSocketConstraint HingeConstraint SpringConstraint RopeConstraint RodConstraint NoCollisionConstraint PrismaticConstraint Torque LineForce Constraint ObjectValue StringValue NumberValue IntValue BoolValue Color3Value Vector3Value CFrameValue RemoteEvent RemoteFunction BindableEvent BindableFunction LuaSourceContainer BaseScript Script LocalScript ModuleScript Animator Animation AnimationTrack AnimationController Tool SpawnLocation ProximityPrompt ClickDetector ForceField Highlight SpecialMesh Decal Texture DataModel ServiceProvider RaycastResult GuiObject GuiBase GuiBase2d LayerCollector ScreenGui Frame TextLabel TextButton TextBox ImageLabel ImageButton ScrollingFrame CanvasGroup ViewportFrame BillboardGui SurfaceGui UICorner UIStroke UIGradient UIListLayout UIGridLayout UIPadding UIScale UIAspectRatioConstraint UISizeConstraint UITextSizeConstraint UIFlexItem UIPageLayout UIComponent UIConstraint UILayout PlayerGui Backpack PlayerScripts Team Teams Mouse PlayerMouse InputObject Configuration ValueBase Accessory Accoutrement BodyColors Shirt Pants HumanoidRootPart SelectionBox Highlight Seat VehicleSeat Speaker AudioPlayer StarterPlayer PlayerGui TextChatService GroupService BadgeService RunService StatsItem Stats LocalizationService ReplicatedFirst Chat Vector3Curve DragDetector`.split(/\s+/);

  const needed = new Map(); // name -> depth
  const queue = [];
  const add = (n, d) => {
    if (!classes.has(n)) return;
    if (needed.has(n) && needed.get(n) <= d) return;
    needed.set(n, d);
    queue.push(n);
  };
  for (const r of roots) add(r, 0);
  // Enums: so os que o jogo usa (o arquivo completo tem ~640 e estoura o limite do analisador)
  const enumWhitelist = new Set(`Material KeyCode UserInputType UserInputState EasingStyle EasingDirection Font TextXAlignment TextYAlignment HumanoidStateType RaycastFilterType PartType SurfaceType NormalId Axis AutomaticSize SizeConstraint ScaleType ZIndexBehavior MouseBehavior RenderPriority CameraType RigType HumanoidRigType FillDirection HorizontalAlignment VerticalAlignment SortOrder ScrollingDirection ApplyStrokeMode TextTruncate MeshType Technology CollisionFidelity RollOffMode ParticleOrientation ParticleEmitterShape ParticleEmitterShapeInOut ParticleEmitterShapeStyle ForceLimitMode VelocityConstraintMode AlignType ActuatorType ModelStreamingMode StreamingIntegrityMode ThumbnailType ThumbnailSize Platform TextInputType HumanoidDisplayDistanceType HumanoidStateType CameraMode DevCameraOcclusionMode ContextActionResult ContextActionPriority EasingStyle BorderMode StrokeSizingMode LineJoinMode ResamplerMode SurfaceGuiSizingMode AdornCullingMode ProximityPromptStyle ProximityPromptExclusivity ProximityPromptInputType KeyInterpolationMode PlaybackState AnimationPriority ReverbType SoundType NormalId ConnectionState FrameStyle TextDirection TextWrap TextTruncate ElasticBehavior ScrollBarInset VerticalScrollBarPosition UIFlexAlignment UIFlexMode ItemLineAlignment SelectionBehavior InterpolationThrottlingMode PhysicsSteppingMethod RejectCharacterDeletions FluidFidelity WaterDirection JointCreationMode LightingStyle Limb BodyPart`.split(/\s+/));
  add("Enum", 0);
  add("EnumItem", 0);
  for (const n of enumWhitelist) {
    add("Enum" + n, 0);
    add("Enum" + n + "_INTERNAL", 0);
  }

  const identRe = /\b[A-Z][A-Za-z0-9_]*\b/g;
  const MAXD = 0;
  while (queue.length) {
    const n = queue.shift();
    const d = needed.get(n);
    const b = classes.get(n);
    if (b.parent) add(b.parent, d); // supertipo entra no mesmo nivel
    if (d >= MAXD) continue;
    const refs = new Set(b.text.match(identRe) || []);
    for (const r of refs) if (r !== n) add(r, d + 1);
  }

  // Todos os blocos que nao sao classes (funcoes/globais/aliases) ficam.
  const out = [];
  const stubNames = new Set();
  const known = new Set([...classes.keys()]);
  const kept = new Set(needed.keys());
  const keptBlocks = [];
  for (const b of blocks) {
    if (b.kind === "class") {
      if (kept.has(b.name)) keptBlocks.push(b.text);
    } else if (b.kind === "alias" && b.name === "ENUM_LIST") {
      const filtered = b.text
        .split("\n")
        .filter((l) => {
          const m = l.match(/^\t(\w+): Enum\w+_INTERNAL,?$/);
          return !m || enumWhitelist.has(m[1]);
        })
        .join("\n");
      keptBlocks.push(filtered);
    } else {
      keptBlocks.push(b.text);
    }
  }
  const body = keptBlocks.join("\n");
  // Descobre nomes referenciados que sao classes removidas -> stub
  for (const id of new Set(body.match(identRe) || [])) {
    if (known.has(id) && !kept.has(id)) stubNames.add(id);
  }
  for (const s of stubNames) {
    out.push(`declare extern type ${s} with end`);
  }
  // metadata inicial (linhas antes do primeiro bloco) e corpo
  const preamble = lines.slice(0, starts[0]).join("\n");
  writeFileSync(outPath, preamble + "\n" + body + "\n" + out.join("\n") + "\n");
  return { kept: kept.size, stubs: stubNames.size, total: classes.size };
}

if (process.argv[1] && process.argv[1].endsWith("make-defs.mjs")) {
  console.log(makeDefs(process.argv[2], process.argv[3]));
}
