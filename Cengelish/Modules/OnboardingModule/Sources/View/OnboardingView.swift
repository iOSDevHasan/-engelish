import ContentKit
import DesignKit
import PuzzleKit
import SwiftUI

/// Onboarding akışının kabı: adım göstergesi, kaydırılabilir içerik ve sabit alt buton.
struct OnboardingView: View {
  @StateObject var viewModel: OnboardingViewModel
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @FocusState private var isNameFocused: Bool
  @State private var isCompactHeight = false

  var body: some View {
    ZStack {
      ScrollViewReader { proxy in
        ScrollView {
          content
            .readableWidth()
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .scrollBounceBehavior(.basedOnSize)
        .task(id: isNameFocused) {
          // Klavye açılınca ad ipucu alt butonun altında kalmasın.
          guard isNameFocused else { return }
          try? await Task.sleep(for: .milliseconds(350))
          withAnimation(Motion.snappy) {
            proxy.scrollTo(ProfileStep.hintID, anchor: .bottom)
          }
        }
      }
      .id(viewModel.step)
      .transition(stepTransition)
    }
    .safeAreaInset(edge: .top, spacing: 0) { header }
    .safeAreaInset(edge: .bottom, spacing: 0) { footer }
    .screenBackground()
    .onGeometryChange(for: Bool.self) { proxy in
      proxy.size.height < OnboardingLayout.compactHeight
    } action: { isCompact in
      isCompactHeight = isCompact
    }
    .animation(reduceMotion ? .easeInOut(duration: 0.2) : Motion.gentle, value: viewModel.step)
    .sheet(item: $viewModel.levelTest) { test in
      LevelTestView(viewModel: test, onAccept: viewModel.acceptLevel) {
        viewModel.levelTest = nil
      }
      .appSheet(detents: [.large])
    }
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.step {
    case .welcome: WelcomeStep(isCompact: isCompactHeight)
    case .profile:
      ProfileStep(viewModel: viewModel, isCompact: isCompactHeight, isFocused: $isNameFocused)
    case .level: LevelStep(selection: $viewModel.level, onTest: viewModel.openLevelTest)
    case .goal: GoalStep(viewModel: viewModel)
    case .data: DataStep(useICloud: $viewModel.useICloud)
    }
  }

  /// Karşılama dışındaki adımlarda üstte duran adım çubuğu.
  @ViewBuilder
  private var header: some View {
    if viewModel.step != .welcome {
      StepHeader(
        step: viewModel.step.rawValue, total: OnboardingStep.allCases.count - 1,
        onBack: goBack
      )
      .readableWidth()
      .background(Palette.background)
      .transition(.opacity)
    }
  }

  private var footer: some View {
    PinnedFooter {
      Button(footerTitle, action: goNext)
        .buttonStyle(.chunky)
      if viewModel.step == .welcome {
        Label("Hesap yok, kayıt yok", systemImage: "checkmark.shield")
          .font(AppFont.caption)
          .foregroundStyle(Palette.muted)
      }
    }
  }

  /// Adım geçişi: yeni adım geçiş yönünden kayarak, eskisi solarak değişir.
  ///
  /// Çıkış yönü bayat kalabildiği için çıkan adım yalnızca solar.
  private var stepTransition: AnyTransition {
    guard !reduceMotion else { return .opacity }
    let offset: CGFloat = viewModel.isMovingForward ? 48 : -48
    return .asymmetric(
      insertion: .offset(x: offset).combined(with: .opacity),
      removal: .opacity)
  }

  /// Alt butonun metni.
  private var footerTitle: String {
    switch viewModel.step {
    case .welcome: "Başlayalım"
    case .data: "Bulmacaya başla"
    default: "Devam"
    }
  }

  /// Klavyeyi kapatıp bir sonraki adıma geçer.
  private func goNext() {
    isNameFocused = false
    viewModel.next()
  }

  /// Klavyeyi kapatıp bir önceki adıma döner.
  private func goBack() {
    isNameFocused = false
    viewModel.back()
  }
}

/// Adım çubuğu ve geri butonu.
private struct StepHeader: View {
  let step: Int
  let total: Int
  let onBack: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Button(action: onBack) { IconCircle("chevron.left") }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel("Geri")
      HStack(spacing: 6) {
        ForEach(1...total, id: \.self) { index in
          Capsule()
            .fill(index <= step ? Palette.accent : Palette.lineStrong)
            .frame(maxWidth: .infinity)
            .frame(height: 6)
        }
      }
      .accessibilityHidden(true)
      Text("\(step) / \(total)")
        .font(AppFont.caption)
        .monospacedDigit()
        .foregroundStyle(Palette.muted)
        .contentTransition(.numericText(value: Double(step)))
        .fixedSize()
        .accessibilityLabel("Adım \(step) / \(total)")
    }
    .padding(.vertical, 8)
  }
}

/// Belirişte zıplayarak gelen kalem maskotu; Hareketi Azalt açıksa yalnızca solarak gelir.
private struct MascotEntrance<Content: View>: View {
  let delay: Double
  @ViewBuilder let content: Content
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var isShown = false

  var body: some View {
    content
      .opacity(isShown ? 1 : 0)
      .scaleEffect(isShown || reduceMotion ? 1 : 0.4, anchor: .bottom)
      .rotationEffect(.degrees(isShown || reduceMotion ? 0 : -18))
      .offset(y: isShown || reduceMotion ? 0 : 24)
      .onAppear {
        let animation = reduceMotion ? Animation.easeOut(duration: 0.25) : Motion.bouncy
        withAnimation(animation.delay(delay)) { isShown = true }
      }
  }
}

// MARK: - Steps

/// 0 · Karşılama.
private struct WelcomeStep: View {
  /// Kısa ekranlarda (iPhone SE) ızgara küçülür.
  let isCompact: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: isCompact ? 12 : 18) {
      ZStack(alignment: .bottomTrailing) {
        PuzzleGridView(
          layout: CrosswordLayout(puzzle: SamplePuzzles.demo), theme: .canli,
          cellSize: isCompact ? 36 : 46,
          highlighted: Set(SamplePuzzles.demo.entries[1].cells),
          active: GridPoint(row: 3, col: 3), activeClue: GridPoint(row: 3, col: 0)
        )
        .rotationEffect(.degrees(-3))
        .appearAnimation()
        MascotEntrance(delay: 0.25) {
          KalemoView(body: AvatarConfig.mascot.body)
            .frame(width: isCompact ? 60 : 74, height: isCompact ? 74 : 90)
        }
        .offset(x: 10, y: 24)
      }
      .frame(maxWidth: .infinity)
      .padding(.top, isCompact ? 8 : 24)
      .padding(.bottom, 24)
      .accessibilityHidden(true)
      Group {
        Eyebrow("Çengelish")
        Text("Kalemle yaz,\nİngilizce öğren.")
          .font(AppFont.display)
          .foregroundStyle(Palette.ink)
          .minimumScaleFactor(0.8)
        Text(
          "Türkçe ipucunu oku, İngilizce kelimeyi kutulara kendi elinle yaz. "
            + "Cevap anahtarıyla kendini kontrol et."
        )
        .font(AppFont.body)
        .foregroundStyle(Palette.muted)
      }
      .fixedSize(horizontal: false, vertical: true)
      .appearAnimation(index: 2)
    }
  }
}

/// 1 · Profil: yalnızca takma ad; avatar her zaman kalem maskotudur.
private struct ProfileStep: View {
  @ObservedObject var viewModel: OnboardingViewModel
  let isCompact: Bool
  var isFocused: FocusState<Bool>.Binding

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Seni tanıyalım").font(AppFont.title).foregroundStyle(Palette.ink)
      Text("Sana nasıl seslenelim? Hesap gerekmez, profilin bu cihazda saklanır.")
        .font(AppFont.body).foregroundStyle(Palette.muted)
        .fixedSize(horizontal: false, vertical: true)
      MascotEntrance(delay: 0.15) {
        AvatarView(viewModel.avatar, size: isCompact ? 96 : 120)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, isCompact ? 4 : 12)
      Text("Takma adın").font(AppFont.section).foregroundStyle(Palette.ink)
      nameField
      Text("Boş bırakırsan \"\(viewModel.defaultNickname)\" olarak görünürsün.")
        .font(AppFont.caption)
        .foregroundStyle(Palette.muted)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, 8)
        .id(Self.hintID)
    }
  }

  /// Klavye açılınca görünür kılınan ad ipucunun kaydırma kimliği.
  static let hintID = "nicknameHint"

  /// Takma ad alanı ve karakter sayacı; yer tutucu varsayılan adı gösterir.
  private var nameField: some View {
    HStack(spacing: 10) {
      TextField(
        "Takma ad",
        text: Binding(get: { viewModel.nickname }, set: viewModel.setNickname),
        prompt: Text(viewModel.defaultNickname).foregroundStyle(Palette.muted)
      )
      .font(AppFont.bodyBold)
      .foregroundStyle(Palette.ink)
      .textInputAutocapitalization(.words)
      .autocorrectionDisabled()
      .submitLabel(.done)
      .focused(isFocused)
      .onSubmit { isFocused.wrappedValue = false }
      .frame(minHeight: 52)
      Text("\(viewModel.nickname.count)/\(viewModel.nicknameLimit)")
        .font(AppFont.tiny)
        .monospacedDigit()
        .foregroundStyle(Palette.muted)
        .fixedSize()
    }
    .padding(.horizontal, 14)
    .frame(minHeight: 52)
    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.surface))
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .strokeBorder(isFocused.wrappedValue ? Palette.accent : Palette.line, lineWidth: 2)
    )
    .animation(Motion.snappy, value: isFocused.wrappedValue)
  }
}

/// 2 · Seviye seçimi.
private struct LevelStep: View {
  @Binding var selection: CEFRLevel?
  let onTest: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Seviyeni seç").font(AppFont.title).foregroundStyle(Palette.ink)
      Text("Bulmacalar seviyene göre hazırlanır. İstediğin zaman değiştirebilirsin.")
        .font(AppFont.body).foregroundStyle(Palette.muted)
        .fixedSize(horizontal: false, vertical: true)
      ForEach(Array(CEFRLevel.allCases.enumerated()), id: \.element) { index, level in
        Button {
          selection = level
        } label: {
          OptionRow(isSelected: selection == level) {
            Text(level.rawValue)
              .font(AppFont.rounded(15, weight: .black))
              .foregroundStyle(.white)
              .frame(width: 40, height: 40)
              .background(RoundedRectangle(cornerRadius: 12).fill(Palette.accent))
            VStack(alignment: .leading, spacing: 2) {
              Text(level.title).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
              Text(level.topics).font(AppFont.caption).foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            RadioMark(isOn: selection == level)
          }
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityAddTraits(selection == level ? .isSelected : [])
        .appearAnimation(index: index)
      }
      Button(action: onTest) {
        HStack(spacing: 12) {
          Image(systemName: "magnifyingglass")
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(Palette.accent)
            .frame(width: 40, height: 40)
          VStack(alignment: .leading, spacing: 2) {
            Text("Emin değilim").font(AppFont.bodyBold).foregroundStyle(Palette.ink)
            Text("2 dakikalık seviye testi").font(AppFont.caption).foregroundStyle(Palette.muted)
          }
          Spacer(minLength: 8)
          Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Palette.muted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .overlay(
          RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
            .strokeBorder(Palette.lineStrong, style: StrokeStyle(lineWidth: 2, dash: [6, 5])))
      }
      .buttonStyle(PressScaleButtonStyle())
      .appearAnimation(index: CEFRLevel.allCases.count)
    }
    .animation(Motion.snappy, value: selection)
    .sensoryFeedback(.selection, trigger: selection)
  }
}

/// 3 · Amaç ve günlük hedef.
private struct GoalStep: View {
  @ObservedObject var viewModel: OnboardingViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Amacın ne?").font(AppFont.title).foregroundStyle(Palette.ink)
      Text("Sana uygun paketleri öne çıkaralım. Birden fazla seçebilirsin.")
        .font(AppFont.body).foregroundStyle(Palette.muted)
        .fixedSize(horizontal: false, vertical: true)
      FlowChips(
        items: LearningGoal.allCases, isOn: { viewModel.goals.contains($0) },
        title: \.title, onTap: viewModel.toggle)
      Text("Günlük hedef").font(AppFont.section).foregroundStyle(Palette.ink).padding(.top, 6)
      HStack(spacing: 10) {
        ForEach(DailyGoalOption.all) { option in
          let isOn = viewModel.dailyGoal == option.count
          Button {
            viewModel.dailyGoal = option.count
          } label: {
            VStack(spacing: 2) {
              Text("\(option.count)").font(AppFont.title)
                .foregroundStyle(isOn ? Palette.accent : Palette.ink)
              Text("bulmaca").font(AppFont.tiny).foregroundStyle(Palette.ink)
              Text("\(option.minutes) · \(option.pace)").font(AppFont.tiny)
                .foregroundStyle(Palette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.top, 2)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, minHeight: 86)
            .background(
              RoundedRectangle(cornerRadius: 18)
                .fill(isOn ? Palette.selection : Palette.surface)
                .overlay(
                  RoundedRectangle(cornerRadius: 18).strokeBorder(
                    isOn ? Palette.accent : Palette.line, lineWidth: 2))
            )
            .scaleEffect(isOn ? 1.03 : 1)
          }
          .buttonStyle(PressScaleButtonStyle())
          .accessibilityAddTraits(isOn ? .isSelected : [])
        }
      }
      .animation(Motion.snappy, value: viewModel.dailyGoal)
      .sensoryFeedback(.selection, trigger: viewModel.dailyGoal)
      VStack(spacing: 10) {
        Toggle(isOn: $viewModel.reminderOn) {
          Label {
            VStack(alignment: .leading, spacing: 2) {
              Text("Günlük hatırlatıcı").font(AppFont.bodyBold).foregroundStyle(Palette.ink)
              Text(viewModel.reminderDetail).font(AppFont.caption)
                .foregroundStyle(Palette.muted)
            }
          } icon: {
            Image(systemName: "bell.fill").foregroundStyle(Palette.accent)
          }
        }
        .tint(Palette.good)
        if viewModel.reminderOn {
          DatePicker("Saat", selection: reminderTime, displayedComponents: .hourAndMinute)
            .font(AppFont.body)
            .foregroundStyle(Palette.ink)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
      }
      // Saat satırının kayma geçişi kartın içinde kırpılır; kartın gölgesi kesilmez.
      .clipped()
      .card(padding: 14)
      .animation(Motion.snappy, value: viewModel.reminderOn)
    }
  }

  /// Hatırlatıcı saatini `Date` olarak bağlar.
  private var reminderTime: Binding<Date> {
    Binding(
      get: {
        Calendar.current.date(
          from: DateComponents(hour: viewModel.reminderHour, minute: viewModel.reminderMinute))
          ?? .now
      },
      set: { date in
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        viewModel.reminderHour = parts.hour ?? 20
        viewModel.reminderMinute = parts.minute ?? 0
      })
  }
}

/// 4 · Veri tercihi.
private struct DataStep: View {
  @Binding var useICloud: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Verilerin sende kalsın").font(AppFont.title).foregroundStyle(Palette.ink)
      Text(
        "Profilin, ilerlemen ve kelime defterin bu cihazda saklanır. İstersen iCloud ile yedekle."
      )
      .font(AppFont.body).foregroundStyle(Palette.muted)
      .fixedSize(horizontal: false, vertical: true)
      choice(
        isOn: !useICloud, icon: "iphone", title: "Sadece bu cihazda",
        detail: "İnternet ve hesap gerekmez. Uygulamayı silersen veriler de silinir."
      ) { useICloud = false }
      choice(
        isOn: useICloud, icon: "icloud.fill", title: "iCloud ile yedekle",
        detail: "Telefon değişse de ilerlemen kaybolmaz. iPhone ve iPad'in senkron kalır.",
        badge: "Önerilen"
      ) { useICloud = true }
      HStack(spacing: 10) {
        Image(systemName: "checkmark.shield.fill")
          .font(.system(size: 22))
          .foregroundStyle(Palette.good)
        Text(
          "Verilerini biz görmeyiz, reklam için kullanılmaz. Yedek senin iCloud hesabında durur."
        )
        .font(AppFont.caption)
        .foregroundStyle(Palette.ink)
        .fixedSize(horizontal: false, vertical: true)
        Spacer(minLength: 0)
      }
      .card(padding: 14)
      Text("İstediğin zaman Ayarlar > Veri ve yedekleme'den değiştirebilirsin.")
        .font(AppFont.caption)
        .foregroundStyle(Palette.muted)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
    }
    .animation(Motion.snappy, value: useICloud)
    .sensoryFeedback(.selection, trigger: useICloud)
  }

  /// Veri tercihi satırı.
  private func choice(
    isOn: Bool, icon: String, title: String, detail: String, badge: String? = nil,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      OptionRow(isSelected: isOn) {
        Image(systemName: icon).font(.system(size: 22, weight: .semibold))
          .foregroundStyle(Palette.accent).frame(width: 32)
        VStack(alignment: .leading, spacing: 3) {
          ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
              Text(title).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
              if let badge { Pill(badge, tone: .good) }
            }
            VStack(alignment: .leading, spacing: 4) {
              if let badge { Pill(badge, tone: .good) }
              Text(title).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
            }
          }
          Text(detail).font(AppFont.caption).foregroundStyle(Palette.muted)
            .fixedSize(horizontal: false, vertical: true)
        }
        Spacer(minLength: 0)
        RadioMark(isOn: isOn)
      }
    }
    .buttonStyle(PressScaleButtonStyle())
    .accessibilityAddTraits(isOn ? .isSelected : [])
  }
}

/// Satır kaydıran seçim çipleri.
private struct FlowChips<Item: Hashable>: View {
  let items: [Item]
  let isOn: (Item) -> Bool
  let title: KeyPath<Item, String>
  let onTap: (Item) -> Void

  var body: some View {
    FlowLayout(spacing: 8) {
      ForEach(items, id: \.self) { item in
        Button {
          onTap(item)
        } label: {
          HStack(spacing: 6) {
            if isOn(item) {
              Image(systemName: "checkmark").font(.system(size: 13, weight: .black))
                .transition(.scale.combined(with: .opacity))
            }
            Text(item[keyPath: title])
          }
          .font(AppFont.bodyBold)
          .foregroundStyle(isOn(item) ? .white : Palette.ink)
          .padding(.horizontal, 16)
          .frame(height: 42)
          .background(Capsule().fill(isOn(item) ? Palette.accent : Palette.surface))
          .overlay(Capsule().strokeBorder(isOn(item) ? .clear : Palette.line, lineWidth: 2))
          .animation(Motion.snappy, value: isOn(item))
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityAddTraits(isOn(item) ? .isSelected : [])
        .sensoryFeedback(.selection, trigger: isOn(item))
      }
    }
  }
}
