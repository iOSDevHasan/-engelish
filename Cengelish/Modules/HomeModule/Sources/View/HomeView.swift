import ContentKit
import DesignKit
import PuzzleKit
import SwiftUI

/// Ana Sayfa sekmesi.
struct HomeView: View {
  @StateObject var viewModel: HomeViewModel

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        header
        streakCard
        dailyCard
        if let item = viewModel.continueItem { continueCard(item) }
        if let word = viewModel.wordOfDay { wordCard(word) }
      }
      .padding(.horizontal, Metrics.gutter)
      .padding(.bottom, 24)
      .frame(maxWidth: 680)
      .frame(maxWidth: .infinity)
    }
    .screenBackground()
    .task { await viewModel.load() }
  }

  private var header: some View {
    HStack(spacing: 12) {
      AvatarView(viewModel.avatar, size: 52)
      VStack(alignment: .leading, spacing: 2) {
        Text(viewModel.greeting).font(AppFont.caption).foregroundStyle(Palette.muted)
        Text(viewModel.name).font(AppFont.headline).foregroundStyle(Palette.ink)
      }
      Spacer()
      Pill(viewModel.level, tone: .accent)
      if viewModel.dueCount > 0 {
        Pill("\(viewModel.dueCount) tekrar", systemImage: "book.closed.fill", tone: .bad)
      }
    }
    .padding(.top, 8)
  }

  private var streakCard: some View {
    VStack(spacing: 14) {
      HStack {
        Image(systemName: "flame.fill").font(.system(size: 24))
          .foregroundStyle(.white)
          .frame(width: 46, height: 46)
          .background(RoundedRectangle(cornerRadius: 14).fill(Palette.streak))
        VStack(alignment: .leading, spacing: 2) {
          Text("\(viewModel.streak) gün").font(AppFont.headline).foregroundStyle(Palette.ink)
          Text("seri · en uzun \(viewModel.longestStreak) gün").font(AppFont.caption)
            .foregroundStyle(Palette.muted)
        }
        Spacer()
        Pill("Bugün \(viewModel.solvedToday)/\(viewModel.dailyGoal)")
      }
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
                }
              }
              .frame(width: 30, height: 30)
            Text(day.label).font(AppFont.tiny).foregroundStyle(Palette.muted)
          }
          .frame(maxWidth: .infinity)
          .accessibilityElement(children: .ignore)
          .accessibilityLabel("\(day.label) \(day.isSolved ? "çözüldü" : "çözülmedi")")
        }
      }
    }
    .card(fill: Palette.streakBackground)
  }

  private var dailyCard: some View {
    HStack(alignment: .center, spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        Eyebrow("Günün Bulmacası", color: .white.opacity(0.85))
        Text(DateText.dayMonth(.now)).font(AppFont.title)
        if let daily = viewModel.daily {
          HStack(spacing: 6) {
            Text(daily.level.rawValue).font(AppFont.tiny.weight(.black))
              .padding(.horizontal, 7).frame(height: 20)
              .background(Capsule().fill(.white.opacity(0.22)))
            Text("\(daily.entries.count) kelime · ~\(daily.estimatedMinutes) dk").font(
              AppFont.caption)
          }
        }
        Button(action: viewModel.openDaily) {
          Label(viewModel.dailyDone ? "Tekrar bak" : "Çöz", systemImage: "chevron.right")
            .labelStyle(TrailingIconLabelStyle())
            .font(AppFont.bodyBold)
            .foregroundStyle(Palette.accent)
            .padding(.horizontal, 16)
            .frame(height: 38)
            .background(Capsule().fill(.white))
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
      }
      .foregroundStyle(.white)
      Spacer(minLength: 0)
      if let daily = viewModel.daily {
        MiniGridView(puzzle: daily, theme: dailyTheme, cellSize: 16)
      }
    }
    .padding(18)
    .background(
      RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
        .fill(
          LinearGradient(
            colors: [Color(hex: 0x6C5CE7), Color(hex: 0x9B8CFF)], startPoint: .topLeading,
            endPoint: .bottomTrailing))
    )
    .overlay(alignment: .topTrailing) {
      if viewModel.dailyDone {
        Pill("Bitti", systemImage: "checkmark", tone: .good).padding(10)
      }
    }
  }

  private func continueCard(_ item: ContinueItem) -> some View {
    Button(action: viewModel.openContinue) {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          Text("Kaldığın yerden devam et").font(AppFont.caption).foregroundStyle(Palette.muted)
          Text(item.title).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
          ProgressBar(value: item.progress, height: 6).padding(.top, 4)
        }
        IconCircle("play.fill", size: 44, accent: true)
      }
      .card()
    }
    .buttonStyle(.plain)
  }

  private func wordCard(_ word: Word) -> some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Eyebrow("Günün kelimesi")
        HStack(alignment: .firstTextBaseline, spacing: 6) {
          Text(word.en).font(AppFont.headline).foregroundStyle(Palette.ink)
          Text(word.ipa).font(AppFont.caption).foregroundStyle(Palette.muted)
        }
        Text(word.meaning).font(AppFont.caption).foregroundStyle(Palette.muted)
      }
      Spacer()
      Button(action: viewModel.speakWordOfDay) { IconCircle("speaker.wave.2.fill") }
        .buttonStyle(.plain)
        .accessibilityLabel("Günün kelimesini dinle")
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
