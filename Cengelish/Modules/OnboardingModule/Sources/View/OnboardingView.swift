import ContentKit
import DesignKit
import PuzzleKit
import SwiftUI

/// Onboarding akışının kabı: adım göstergesi, içerik ve alt buton.
struct OnboardingView: View {
  @StateObject var viewModel: OnboardingViewModel

  var body: some View {
    VStack(spacing: 0) {
      if viewModel.step != .welcome {
        StepHeader(step: viewModel.step.rawValue, total: 4, onBack: viewModel.back)
      }
      ScrollView {
        content
          .padding(.horizontal, Metrics.gutter)
          .padding(.bottom, 24)
          .frame(maxWidth: 560)
          .frame(maxWidth: .infinity)
      }
      .scrollDismissesKeyboard(.interactively)
      footer
    }
    .screenBackground()
    .animation(.snappy, value: viewModel.step)
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.step {
    case .welcome: WelcomeStep()
    case .profile: ProfileStep(viewModel: viewModel)
    case .level: LevelStep(selection: $viewModel.level)
    case .goal: GoalStep(viewModel: viewModel)
    case .data: DataStep(useICloud: $viewModel.useICloud)
    }
  }

  private var footer: some View {
    VStack(spacing: 10) {
      Button(
        viewModel.step == .welcome ? "Başlayalım" : viewModel.step == .data ? "Bitir" : "Devam"
      ) {
        viewModel.next()
      }
      .buttonStyle(.chunky)
      if viewModel.step == .welcome {
        Label("Hesap yok, kayıt yok", systemImage: "checkmark.shield")
          .font(AppFont.caption)
          .foregroundStyle(Palette.muted)
      }
    }
    .padding(.horizontal, Metrics.gutter)
    .padding(.bottom, 12)
    .frame(maxWidth: 560)
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
        .buttonStyle(.plain)
        .accessibilityLabel("Geri")
      HStack(spacing: 6) {
        ForEach(1...total, id: \.self) { index in
          Capsule().fill(index <= step ? Palette.accent : Palette.lineStrong).frame(height: 6)
        }
      }
      Text("\(step) / \(total)").font(AppFont.caption).foregroundStyle(Palette.muted)
    }
    .padding(.horizontal, Metrics.gutter)
    .padding(.vertical, 8)
  }
}

// MARK: - Steps

/// 0 · Karşılama.
private struct WelcomeStep: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      ZStack(alignment: .bottomTrailing) {
        PuzzleGridView(
          layout: CrosswordLayout(puzzle: SamplePuzzles.demo), theme: .canli, cellSize: 46,
          highlighted: Set(SamplePuzzles.demo.entries[1].cells),
          active: GridPoint(row: 3, col: 3), activeClue: GridPoint(row: 3, col: 0)
        )
        .rotationEffect(.degrees(-3))
        KalemoView(body: .yellow).frame(width: 74, height: 90).offset(x: 10, y: 24)
      }
      .frame(maxWidth: .infinity)
      .padding(.top, 24)
      Eyebrow("Çengelish")
      Text("Kalemle yaz,\nİngilizce öğren.")
        .font(AppFont.display)
        .foregroundStyle(Palette.ink)
      Text(
        "Türkçe ipucunu oku, İngilizce kelimeyi kutulara kendi elinle yaz. Cevap anahtarıyla kendini kontrol et."
      )
      .font(AppFont.body)
      .foregroundStyle(Palette.muted)
    }
  }
}

/// 1 · Profil oluştur.
private struct ProfileStep: View {
  @ObservedObject var viewModel: OnboardingViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Seni tanıyalım").font(AppFont.title).foregroundStyle(Palette.ink)
      Text("Kendi Kalemo'nu oluştur. Hesap gerekmez, profilin bu cihazda kalır.")
        .font(AppFont.body).foregroundStyle(Palette.muted)
      AvatarView(viewModel.avatar, size: 120).frame(maxWidth: .infinity)
      Text("Renk").font(AppFont.section).foregroundStyle(Palette.ink)
      BodyColorPicker(selection: $viewModel.avatar.body)
      Text("Aksesuar").font(AppFont.section).foregroundStyle(Palette.ink)
      AccessoryPicker(
        selection: $viewModel.avatar.accessory, options: viewModel.freeAccessories,
        body: viewModel.avatar.body)
      Text("Arka plan").font(AppFont.section).foregroundStyle(Palette.ink)
      BackgroundPicker(selection: $viewModel.avatar.background) { $0 == .night || $0 == .coral }
      Text("Takma ad").font(AppFont.section).foregroundStyle(Palette.ink)
      HStack {
        TextField(
          "Örn. Deniz",
          text: Binding(get: { viewModel.nickname }, set: viewModel.setNickname)
        )
        .font(AppFont.bodyBold)
        .textInputAutocapitalization(.words)
        .submitLabel(.done)
        Text("\(viewModel.nickname.count)/\(viewModel.nicknameLimit)")
          .font(AppFont.tiny).foregroundStyle(Palette.muted)
      }
      .padding(14)
      .background(RoundedRectangle(cornerRadius: 16).fill(Palette.surface))
      .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Palette.line, lineWidth: 2))
      Text("Boş bırakırsan \"Kalemci\" olarak görünürsün.").font(AppFont.tiny)
        .foregroundStyle(Palette.muted)
    }
  }
}

/// 2 · Seviye seçimi.
private struct LevelStep: View {
  @Binding var selection: CEFRLevel?

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("İngilizcen ne seviyede?").font(AppFont.title).foregroundStyle(Palette.ink)
      Text("Bulmacaları buna göre seçeriz. Sonra değiştirebilirsin.")
        .font(AppFont.body).foregroundStyle(Palette.muted)
      ForEach(CEFRLevel.allCases, id: \.self) { level in
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
            }
            Spacer()
            RadioMark(isOn: selection == level)
          }
        }
        .buttonStyle(.plain)
      }
      Button("Bilmiyorum, A1'den başlayayım") { selection = .a1 }
        .buttonStyle(ChunkyButtonStyle(.ghost))
    }
  }
}

/// 3 · Amaç ve günlük hedef.
private struct GoalStep: View {
  @ObservedObject var viewModel: OnboardingViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Amacın ne?").font(AppFont.title).foregroundStyle(Palette.ink)
      Text("Birden fazla seçebilirsin. Sınav seçersen o paketi öneririz.")
        .font(AppFont.body).foregroundStyle(Palette.muted)
      FlowChips(
        items: LearningGoal.allCases, isOn: { viewModel.goals.contains($0) },
        title: \.title, onTap: viewModel.toggle)
      Text("Günlük hedef").font(AppFont.section).foregroundStyle(Palette.ink).padding(.top, 6)
      HStack(spacing: 10) {
        ForEach([1, 2, 3], id: \.self) { count in
          Button {
            viewModel.dailyGoal = count
          } label: {
            VStack(spacing: 2) {
              Text("\(count)").font(AppFont.title)
              Text("bulmaca").font(AppFont.tiny)
            }
            .foregroundStyle(viewModel.dailyGoal == count ? Palette.accent : Palette.ink)
            .frame(maxWidth: .infinity, minHeight: 74)
            .background(
              RoundedRectangle(cornerRadius: 18)
                .fill(viewModel.dailyGoal == count ? Palette.selection : Palette.surface)
                .overlay(
                  RoundedRectangle(cornerRadius: 18).strokeBorder(
                    viewModel.dailyGoal == count ? Palette.accent : Palette.line, lineWidth: 2)))
          }
          .buttonStyle(.plain)
        }
      }
      Toggle(isOn: $viewModel.reminderOn) {
        VStack(alignment: .leading, spacing: 2) {
          Text("Günlük hatırlatıcı").font(AppFont.bodyBold)
          Text("Her akşam 20.00'de Günün Bulmacası").font(AppFont.caption)
            .foregroundStyle(Palette.muted)
        }
      }
      .tint(Palette.good)
      .card(padding: 14)
    }
  }
}

/// 4 · Veri tercihi.
private struct DataStep: View {
  @Binding var useICloud: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Verilerin sende kalsın").font(AppFont.title).foregroundStyle(Palette.ink)
      Text(
        "Hesap açmıyoruz. Profilin, ilerlemen ve defterin cihazında saklanır. İstersen kendi iCloud hesabına yedekleriz."
      )
      .font(AppFont.body).foregroundStyle(Palette.muted)
      choice(
        isOn: !useICloud, icon: "iphone", title: "Sadece bu cihazda",
        detail: "Telefon değişirse veriler taşınmaz; dosyaya dışa aktarabilirsin."
      ) { useICloud = false }
      choice(
        isOn: useICloud, icon: "icloud.fill", title: "iCloud ile yedekle",
        detail: "iPhone ve iPad arasında senkron. Veriler sadece senin iCloud hesabında.",
        badge: "Önerilen"
      ) { useICloud = true }
      Label(
        "Bu tercihi Ayarlar → Veri ve yedekleme'den değiştirebilirsin.", systemImage: "info.circle"
      )
      .font(AppFont.caption).foregroundStyle(Palette.muted)
    }
  }

  private func choice(
    isOn: Bool, icon: String, title: String, detail: String, badge: String? = nil,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      OptionRow(isSelected: isOn) {
        Image(systemName: icon).font(.system(size: 22, weight: .semibold))
          .foregroundStyle(Palette.accent).frame(width: 32)
        VStack(alignment: .leading, spacing: 3) {
          HStack(spacing: 6) {
            Text(title).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
            if let badge { Pill(badge, tone: .good) }
          }
          Text(detail).font(AppFont.caption).foregroundStyle(Palette.muted)
            .fixedSize(horizontal: false, vertical: true)
        }
        Spacer(minLength: 0)
        RadioMark(isOn: isOn)
      }
    }
    .buttonStyle(.plain)
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
          Text(item[keyPath: title])
            .font(AppFont.bodyBold)
            .foregroundStyle(isOn(item) ? .white : Palette.ink)
            .padding(.horizontal, 16)
            .frame(height: 42)
            .background(Capsule().fill(isOn(item) ? Palette.accent : Palette.surface))
            .overlay(Capsule().strokeBorder(isOn(item) ? .clear : Palette.line, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn(item) ? .isSelected : [])
      }
    }
  }
}
