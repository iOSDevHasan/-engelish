import ContentKit
import DesignKit
import PuzzleKit
import SwiftUI
import WordKit

/// Ana Sayfa sekmesi.
struct HomeView: View {
  @StateObject var viewModel: HomeViewModel

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        header.appearAnimation(index: 0)
        streakCard.appearAnimation(index: 1)
        dailyCard.appearAnimation(index: 2)
        if viewModel.showsPlusPromo {
          plusPromo
            .appearAnimation(index: 3)
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
        }
        if let item = viewModel.continueItem {
          continueCard(item).appearAnimation(index: 4)
        }
        if let word = viewModel.wordOfDay {
          wordCard(word).appearAnimation(index: 5)
        }
      }
      .animation(Motion.gentle, value: viewModel.isPlus)
      .padding(.horizontal, Metrics.gutter)
      .padding(.bottom, 24)
      .frame(maxWidth: 680)
      .frame(maxWidth: .infinity)
    }
    .scrollIndicators(.hidden)
    .statusBarScrim()
    .screenBackground()
    .task { await viewModel.load() }
    .appBottomSheet(isPresented: $viewModel.isReminderSheetOpen) {
      ReminderSheet(viewModel: viewModel)
    }
  }

  // MARK: - Header

  /// Avatar, selamlama, günlük hedef ve sağ üstte Plus butonu (her zaman paywall'u açar).
  private var header: some View {
    HStack(spacing: 12) {
      UserAvatarView(photo: viewModel.photo, avatar: viewModel.avatar, size: 52)
      VStack(alignment: .leading, spacing: 2) {
        Text(viewModel.greeting).font(AppFont.caption).foregroundStyle(Palette.muted)
        Text(viewModel.goalText).font(AppFont.headline).foregroundStyle(Palette.ink)
          .fixedSize(horizontal: false, vertical: true)
      }
      Spacer(minLength: 8)
      HomePlusButton(isMember: viewModel.isPlus, action: viewModel.openPaywall)
    }
    .padding(.top, 8)
  }

  // MARK: - Streak

  /// Seri, haftalık takvim, seri dondurma (Plus) satırı ve hatırlatıcı kısayolu.
  private var streakCard: some View {
    VStack(spacing: 14) {
      HStack {
        Image(systemName: "flame.fill").font(.system(size: 24))
          .foregroundStyle(.white)
          .symbolEffect(.bounce, value: viewModel.streak)
          .frame(width: 46, height: 46)
          .background(RoundedRectangle(cornerRadius: 14).fill(Palette.streak))
        VStack(alignment: .leading, spacing: 2) {
          Text("\(viewModel.streak) gün").font(AppFont.headline).foregroundStyle(Palette.ink)
            .contentTransition(.numericText(value: Double(viewModel.streak)))
          Text("seri · en uzun \(viewModel.longestStreak) gün").font(AppFont.caption)
            .foregroundStyle(Palette.muted)
            .contentTransition(.numericText(value: Double(viewModel.longestStreak)))
        }
        Spacer()
        Pill("Bugün \(viewModel.solvedToday)/\(viewModel.dailyGoal)")
          .contentTransition(.numericText(value: Double(viewModel.solvedToday)))
      }
      .animation(Motion.bouncy, value: viewModel.streak)
      .animation(Motion.snappy, value: viewModel.solvedToday)
      weekRow
      if let hint = viewModel.freezeHint {
        freezeHintRow(hint)
      } else if viewModel.showsFreezeTeaser {
        freezeTeaser
      }
      reminderShortcut
    }
    .card(fill: Palette.streakBackground)
  }

  /// Hatırlatıcı panelini açan sade satır ("Hatırlatıcı her gün 20:00").
  private var reminderShortcut: some View {
    Button(action: viewModel.openReminders) {
      HStack(spacing: 8) {
        Image(systemName: viewModel.reminderOn ? "bell.fill" : "bell.badge")
          .font(.system(size: 13, weight: .bold))
          .foregroundStyle(Palette.streak)
          .contentTransition(.symbolEffect(.replace))
        Text(viewModel.reminderShortcut)
          .font(AppFont.caption)
          .foregroundStyle(Palette.ink)
          .contentTransition(.opacity)
        Spacer(minLength: 4)
        Image(systemName: "chevron.right")
          .font(.system(size: 11, weight: .black))
          .foregroundStyle(Palette.muted)
      }
      .frame(minHeight: 32)
      .contentShape(Rectangle())
    }
    .buttonStyle(PressScaleButtonStyle())
    .accessibilityLabel("Hatırlatıcı")
    .accessibilityValue(viewModel.reminderOn ? viewModel.reminderDetail : "Kapalı")
  }

  /// Haftanın yedi günü; çözülen günler turuncu ve işaretli.
  private var weekRow: some View {
    HStack(spacing: 6) {
      ForEach(viewModel.week) { day in
        VStack(spacing: 4) {
          Circle()
            .fill(day.isSolved ? Palette.streak : Palette.surface)
            .overlay(
              Circle().strokeBorder(
                day.isToday ? Palette.streak : Palette.lineStrong, lineWidth: 2)
            )
            .overlay {
              if day.isSolved {
                Image(systemName: "checkmark").font(.system(size: 11, weight: .black))
                  .foregroundStyle(.white)
                  .transition(.scale.combined(with: .opacity))
              }
            }
            .frame(width: 30, height: 30)
            .animation(Motion.bouncy, value: day.isSolved)
          Text(day.label).font(AppFont.tiny).foregroundStyle(Palette.muted)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(day.label) \(day.isSolved ? "çözüldü" : "çözülmedi")")
      }
    }
  }

  /// Plus kullanıcısının seri dondurma durumu.
  private func freezeHintRow(_ hint: String) -> some View {
    Label(hint, systemImage: "snowflake")
      .font(AppFont.caption)
      .foregroundStyle(Palette.accent)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.leading, 12)
      .padding(.trailing, 44)
      .padding(.vertical, 10)
      .background(
        RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Palette.surface)
          .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .strokeBorder(Palette.cardBorder, lineWidth: 1))
      )
      .plusCorner(true, inset: -6)
  }

  /// Plus olmayan kullanıcıya seri dondurmayı tanıtan, paywall'u açan altın satır.
  private var freezeTeaser: some View {
    Button(action: viewModel.openPaywall) {
      HStack(spacing: 10) {
        Image(systemName: "snowflake").font(.system(size: 16, weight: .bold))
          .foregroundStyle(Palette.accent)
        VStack(alignment: .leading, spacing: 1) {
          Text("Seri dondurma").font(AppFont.caption.weight(.black)).foregroundStyle(Palette.ink)
          Text("Bir gün kaçırsan da serin bozulmasın")
            .font(AppFont.caption).foregroundStyle(Palette.muted)
            .fixedSize(horizontal: false, vertical: true)
        }
        Spacer(minLength: 4)
        Image(systemName: "chevron.right").font(.system(size: 12, weight: .black))
          .foregroundStyle(Palette.muted)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
      .background(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .fill(Palette.surface)
          .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .fill(Palette.gold.opacity(0.14))
          )
          .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .strokeBorder(Palette.gold.opacity(0.8), lineWidth: 1.5))
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(PressScaleButtonStyle())
    .plusCorner(true, inset: -6)
    .accessibilityHint("\(PlusBrand.name) ekranını açar")
  }

  // MARK: - Daily puzzle

  /// Günün Bulmacası kartı; tamamı dokunulabilir, basınca hafifçe küçülür.
  private var dailyCard: some View {
    Button(action: viewModel.openDaily) {
      HStack(alignment: .center, spacing: 12) {
        VStack(alignment: .leading, spacing: 6) {
          Eyebrow("Günün Bulmacası", color: .white.opacity(0.85))
          Text(DateText.dayMonth(.now)).font(AppFont.title)
          if let daily = viewModel.daily {
            HStack(spacing: 6) {
              Text(daily.level.rawValue).font(AppFont.tiny.weight(.black))
                .padding(.horizontal, 7).frame(height: 20)
                .background(Capsule().fill(.white.opacity(0.22)))
              Text("\(daily.entries.count) kelime · ~\(daily.estimatedMinutes) dk")
                .font(AppFont.caption)
            }
          }
          Label(viewModel.dailyDone ? "Tekrar bak" : "Çöz", systemImage: "chevron.right")
            .labelStyle(TrailingIconLabelStyle())
            .font(AppFont.bodyBold)
            .foregroundStyle(Palette.accent)
            .padding(.horizontal, 16)
            .frame(height: 38)
            .background(Capsule().fill(.white))
            .padding(.top, 4)
        }
        .foregroundStyle(.white)
        Spacer(minLength: 0)
        if let daily = viewModel.daily {
          MiniGridView(puzzle: daily, theme: dailyTheme, cellSize: 16)
        }
      }
      .padding(18)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
          .fill(
            LinearGradient(
              colors: [Color(hex: 0x6C5CE7), Color(hex: 0x9B8CFF)], startPoint: .topLeading,
              endPoint: .bottomTrailing)
          )
          .shadow(color: Color(hex: 0x6C5CE7).opacity(0.3), radius: 12, y: 8)
      )
      .overlay(alignment: .topTrailing) {
        if viewModel.dailyDone {
          // Kartın üst kenarına oturan rozet: sağdaki mini ızgaranın kutularını örtmez.
          Pill("Bitti", systemImage: "checkmark", tone: .good)
            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
            .padding(.trailing, 14)
            .offset(y: -12)
            .transition(.scale.combined(with: .opacity))
        }
      }
      .contentShape(RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous))
    }
    .buttonStyle(PressScaleButtonStyle())
    .disabled(viewModel.daily == nil)
    .animation(Motion.bouncy, value: viewModel.dailyDone)
    .accessibilityLabel("Günün Bulmacası, \(DateText.dayMonth(.now))")
    .accessibilityHint(viewModel.dailyDone ? "Tekrar bak" : "Çöz")
  }

  // MARK: - Plus

  /// Plus olmayan kullanıcıya gösterilen, paywall'u açan kart.
  private var plusPromo: some View {
    PlusPromoCard(
      title: PlusBrand.name,
      subtitle: "Seri dondurma, bulmacayla kelime tekrarı ve daha fazlası",
      action: viewModel.openPaywall)
  }

  // MARK: - Continue & word

  /// Yarım kalan bulmaca kartı.
  private func continueCard(_ item: ContinueItem) -> some View {
    Button(action: viewModel.openContinue) {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          Text("Kaldığın yerden devam et").font(AppFont.caption).foregroundStyle(Palette.muted)
          Text(item.title).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
            .fixedSize(horizontal: false, vertical: true)
          ProgressBar(value: item.progress, height: 6).padding(.top, 4)
        }
        IconCircle("play.fill", size: 44, accent: true)
      }
      .card()
      .contentShape(Rectangle())
    }
    .buttonStyle(PressScaleButtonStyle())
  }

  /// Günün kelimesi kartı.
  private func wordCard(_ word: Word) -> some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Eyebrow("Günün kelimesi")
        HStack(alignment: .firstTextBaseline, spacing: 6) {
          Text(word.en).font(AppFont.headline).foregroundStyle(Palette.ink)
          Text(word.ipa).font(AppFont.caption).foregroundStyle(Palette.muted)
        }
        Text(word.meaning).font(AppFont.caption).foregroundStyle(Palette.muted)
          .fixedSize(horizontal: false, vertical: true)
      }
      Spacer()
      SpeakerButton(
        word: word.en, size: 40, isRound: true, label: "Günün kelimesini dinle",
        action: viewModel.speakWordOfDay)
    }
    .card()
  }

  /// Mor kart üzerinde okunur mini ızgara teması.
  private var dailyTheme: PuzzleTheme {
    PuzzleTheme(
      id: "daily", name: "", detail: "", isPremium: false, cell: .white.opacity(0.9),
      clue: .white.opacity(0.35), clueInk: .white, line: .clear, pen: .white, pencil: .white,
      blank: .clear, stripedBlanks: false, highlight: Color(hex: 0xFFE7A0), active: .white,
      activeRing: nil, arrow: .white, gap: 2, border: 0, cornerRatio: 0.2, keyInk: .white)
  }
}

/// Seri kartındaki hatırlatıcı satırıyla açılan alttan panel (`appBottomSheet`); içeriğe göre
/// boylanır.
private struct ReminderSheet: View {
  @ObservedObject var viewModel: HomeViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: 4) {
        Text("Hatırlatıcı").font(AppFont.headline).foregroundStyle(Palette.ink)
        Text("Her gün seçtiğin saatte Günün Bulmacası için haber veririz.")
          .font(AppFont.caption).foregroundStyle(Palette.muted)
          .fixedSize(horizontal: false, vertical: true)
      }
      settingsCard
      Label(
        "Serin bozulmak üzereyse akşam bir kez daha haber veririz.", systemImage: "flame.fill"
      )
      .font(AppFont.caption)
      .foregroundStyle(Palette.muted)
      .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.horizontal, Metrics.gutter)
    .padding(.top, 12)
    .padding(.bottom, 16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .animation(Motion.snappy, value: viewModel.reminderOn)
    .alert(
      "Bilgi",
      isPresented: Binding(get: { viewModel.notice != nil }, set: { _ in viewModel.notice = nil })
    ) {
      Button("Tamam", role: .cancel) {}
    } message: {
      Text(viewModel.notice ?? "")
    }
  }

  /// Açma/kapama anahtarı ve saat seçici.
  private var settingsCard: some View {
    VStack(spacing: 12) {
      Toggle(
        isOn: Binding(
          get: { viewModel.reminderOn },
          set: { on in Task { await viewModel.setReminder(on) } })
      ) {
        HStack(spacing: 12) {
          Image(systemName: "bell.fill")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(Palette.accent)
            .symbolEffect(.bounce, value: viewModel.reminderOn)
            .frame(width: 36, height: 36)
            .background(Circle().fill(Palette.surface2))
          VStack(alignment: .leading, spacing: 2) {
            Text("Günlük hatırlatıcı").font(AppFont.bodyBold).foregroundStyle(Palette.ink)
            Text(viewModel.reminderDetail).font(AppFont.caption)
              .foregroundStyle(Palette.muted)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
      }
      .tint(Palette.good)
      if viewModel.reminderOn {
        Rectangle().fill(Palette.line).frame(height: 1)
        DatePicker(selection: time, displayedComponents: .hourAndMinute) {
          Text("Saat").font(AppFont.bodyBold).foregroundStyle(Palette.ink)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
    .card(padding: 14)
  }

  /// Hatırlatıcı saatini `Date` olarak bağlar.
  private var time: Binding<Date> {
    Binding(
      get: {
        Calendar.current.date(
          from: DateComponents(
            hour: viewModel.reminderTime.hour, minute: viewModel.reminderTime.minute)) ?? .now
      },
      set: { date in
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        viewModel.setReminderTime(hour: parts.hour ?? 20, minute: parts.minute ?? 0)
      })
  }
}
