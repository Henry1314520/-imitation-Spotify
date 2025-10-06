//
//  ContentView.swift
//  Spotify Clone
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Main App Entry with Splash Screen

struct ContentView: View {
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
            } else {
                MainAppView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: showSplash)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showSplash = false
            }
        }
    }
}

// MARK: - Splash Screen

struct SplashScreenView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            SpotifyLogoView()
                .frame(width: 120, height: 120)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

// MARK: - Spotify Logo

struct SpotifyLogoView: View {
    var body: some View {
        Image("spotify")
            .resizable()
            .renderingMode(.original)
            .scaledToFit()
            .accessibilityLabel("Spotify")
    }
}

// MARK: - Main App View

struct MainAppView: View {
    @State private var currentTrack: Track? = SampleData.playlists.first?.tracks.first
    @State private var isPlaying: Bool = false
    @State private var playbackProgress: Double = 0.0
    @State private var showingNowPlaying: Bool = false
    @State private var selectedTab: Tab = .home
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(
                    playlists: SampleData.playlists,
                    onPlayTrack: play
                )
                .tag(Tab.home)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首頁")
                }
                
                SearchView()
                    .tag(Tab.search)
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("搜尋")
                    }
                
                LibraryView(playlists: SampleData.playlists, onPlayTrack: play)
                    .tag(Tab.library)
                    .tabItem {
                        Image(systemName: "books.vertical.fill")
                        Text("你的音樂庫")
                    }
            }
            .accentColor(Color(hex: "#1DB954"))
            
            if let track = currentTrack {
                MiniPlayerView(
                    track: track,
                    isPlaying: $isPlaying,
                    progress: $playbackProgress
                )
                .onTapGesture {
                    showingNowPlaying = true
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 50)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .preferredColorScheme(.dark)
        .animation(.snappy, value: currentTrack)
        .fullScreenCover(isPresented: $showingNowPlaying) {
            if let track = currentTrack {
                NowPlayingView(
                    track: track,
                    isPlaying: $isPlaying,
                    progress: $playbackProgress,
                    onDismiss: { showingNowPlaying = false },
                    onNext: nextTrack,
                    onPrev: prevTrack
                )
            }
        }
        .task(id: isPlaying) {
            guard isPlaying else { return }
            while isPlaying {
                try? await Task.sleep(nanoseconds: 250_000_000)
                playbackProgress = min(1.0, playbackProgress + 0.005)
                if playbackProgress >= 1.0 {
                    nextTrack()
                }
            }
        }
    }
    
    private func play(_ track: Track) {
        currentTrack = track
        isPlaying = true
        playbackProgress = 0
    }
    
    private func nextTrack() {
        guard let track = currentTrack else { return }
        if let playlist = SampleData.playlists.first(where: { $0.tracks.contains(track) }),
           let idx = playlist.tracks.firstIndex(of: track) {
            let nextIdx = (idx + 1) % playlist.tracks.count
            currentTrack = playlist.tracks[nextIdx]
        }
        playbackProgress = 0
        isPlaying = true
    }
    
    private func prevTrack() {
        guard let track = currentTrack else { return }
        if let playlist = SampleData.playlists.first(where: { $0.tracks.contains(track) }),
           let idx = playlist.tracks.firstIndex(of: track) {
            let prevIdx = (idx - 1 + playlist.tracks.count) % playlist.tracks.count
            currentTrack = playlist.tracks[prevIdx]
        }
        playbackProgress = 0
        isPlaying = true
    }
    
    enum Tab {
        case home, search, library
    }
}

// MARK: - Home View

struct HomeView: View {
    let playlists: [Playlist]
    let onPlayTrack: (Track) -> Void
    @State private var selectedCategory = "所有"
    
    private let categories = ["所有", "音樂", "Podcast"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Greeting + Category buttons
                VStack(alignment: .leading, spacing: 10) {
                    /*HStack {
                        Text(greeting())
                            .font(.largeTitle).bold()
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)*/
                    
                    // Spotify-style category buttons + avatar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            // 🟢 小圓形頭像（可換成你的圖片）
                            Image("me")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 36, height: 36)
                                .clipShape(Circle()) //
                                .foregroundColor(.white)
                                .padding(.leading, 8)
                            
                            // 類別按鈕
                            ForEach(categories, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    Text(category)
                                        .font(.subheadline)
                                        .fontWeight(selectedCategory == category ? .semibold : .regular)
                                        .foregroundColor(
                                            selectedCategory == category ? .black : .white
                                        )
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedCategory == category
                                                ? Color(hex: "#1DB954")
                                                : Color(white: 0.2)
                                        )
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Quick access grid (2x3)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(playlists.prefix(6)) { pl in
                        QuickAccessCard(playlist: pl) {
                            if let first = pl.tracks.first {
                                onPlayTrack(first)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Your top mixes
                VStack(alignment: .leading, spacing: 12) {
                    Text("你的熱門混合")
                        .font(.title2).bold()
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(playlists) { pl in
                                PlaylistCard(playlist: pl) {
                                    if let random = pl.tracks.randomElement() {
                                        onPlayTrack(random)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Recently played
                VStack(alignment: .leading, spacing: 12) {
                    Text("最近播放")
                        .font(.title2).bold()
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(playlists.shuffled()) { pl in
                                PlaylistCard(playlist: pl) {
                                    if let random = pl.tracks.randomElement() {
                                        onPlayTrack(random)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer(minLength: 100)
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    /*private func greeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "早安"
        case 12..<18: return "午安"
        default: return "晚安"
        }
    }time detect*/
}



struct QuickAccessCard: View {
    let playlist: Playlist
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                ArtworkView(imageName: playlist.artworkImageName, color: playlist.artworkColor)
                    .frame(width: 54, height: 54)
                
                Text(playlist.name)
                    .font(.footnote).bold()
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer(minLength: 0)
            }
            .frame(height: 54)
            .background(Color(white: 0.15))
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}

struct PlaylistCard: View {
    let playlist: Playlist
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                ArtworkView(imageName: playlist.artworkImageName, color: playlist.artworkColor)
                    .frame(width: 140, height: 140)
                    .cornerRadius(4)
                
                Text(playlist.name)
                    .font(.subheadline).bold()
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(playlist.subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            .frame(width: 140)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Search View

struct SearchView: View {
    @State private var searchText = ""
    private let grid = [GridItem(.flexible()), GridItem(.flexible())]
    private let tiles: [GenreTile] = SampleData.genres
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("搜尋")
                        .font(.largeTitle).bold()
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Search bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.black)
                        TextField("藝人、歌曲或 Podcast", text: $searchText)
                            .foregroundColor(.black)
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    
                    Text("瀏覽全部")
                        .font(.headline).bold()
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    LazyVGrid(columns: grid, spacing: 12) {
                        ForEach(tiles) { tile in
                            GenreCard(tile: tile)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color.black)
        }
    }
}

struct GenreCard: View {
    let tile: GenreTile
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(tile.color)
                .frame(height: 100)
            
            Text(tile.title)
                .font(.headline).bold()
                .foregroundColor(.white)
                .padding(16)
            
            Image(systemName: "music.note")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.3))
                .rotationEffect(.degrees(25))
                .offset(x: 80, y: 40)
        }
    }
}

// MARK: - Library View

struct LibraryView: View {
    let playlists: [Playlist]
    let onPlayTrack: (Track) -> Void
    @State private var selectedFilter = "播放清單"
    
    let filters = ["播放清單", "Podcast", "藝人", "專輯"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("你的音樂庫")
                        .font(.headline).bold()
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                        Image(systemName: "plus")
                    }
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.black)
                
                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filters, id: \.self) { filter in
                            FilterChip(title: filter, isSelected: selectedFilter == filter) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color.black)
                
                // List
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(playlists) { pl in
                            Button {
                                if let track = pl.tracks.first {
                                    onPlayTrack(track)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    ArtworkView(imageName: pl.artworkImageName, color: pl.artworkColor)
                                        .frame(width: 64, height: 64)
                                        .cornerRadius(4)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(pl.name)
                                            .font(.subheadline).bold()
                                            .foregroundColor(.white)
                                        
                                        HStack(spacing: 4) {
                                            Image(systemName: "pin.fill")
                                                .font(.caption2)
                                            Text("播放清單 · \(pl.tracks.count) 首歌")
                                                .font(.caption)
                                        }
                                        .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 8)
                }
            }
            .background(Color.black)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote).bold()
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color(hex: "#1DB954") : Color(white: 0.15))
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mini Player

struct MiniPlayerView: View {
    let track: Track
    @Binding var isPlaying: Bool
    @Binding var progress: Double
    
    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                Rectangle()
                    .fill(Color(hex: "#1DB954"))
                    .frame(width: geo.size.width * progress, height: 2)
            }
            .frame(height: 2)
            
            HStack(spacing: 12) {
                ArtworkView(imageName: track.artworkImageName, color: track.color)
                    .frame(width: 48, height: 48)
                    .cornerRadius(4)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.footnote).bold()
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(track.artist)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "speaker.wave.2.fill")
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                Button {
                    isPlaying.toggle()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Color(white: 0.15))
            .cornerRadius(8)
        }
    }
}

// MARK: - Now Playing View

struct NowPlayingView: View {
    let track: Track
    @Binding var isPlaying: Bool
    @Binding var progress: Double
    var onDismiss: () -> Void
    var onNext: () -> Void
    var onPrev: () -> Void
    
    @State private var isShuffle = false
    @State private var repeatMode = 0 // 0: off, 1: all, 2: one
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [track.color, Color.black, Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "chevron.down")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("正在播放歌曲來自")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text("Daily Mix")
                            .font(.caption).bold()
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button {} label: {
                        Image(systemName: "ellipsis")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                
                Spacer()
                
                // Artwork
                ArtworkView(imageName: track.artworkImageName, color: track.color)
                    .frame(width: 340, height: 340)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
                    .padding(.horizontal, 24)
                
                // Track info
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(track.title)
                            .font(.title3).bold()
                            .foregroundColor(.white)
                        Text(track.artist)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button {} label: {
                        Image(systemName: "heart")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Progress bar
                VStack(spacing: 8) {
                    Slider(value: $progress, in: 0...1)
                        .accentColor(.white)
                    
                    HStack {
                        Text(timeString(seconds: Int(progress * 210)))
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text(timeString(seconds: 210))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Controls
                HStack(spacing: 24) {
                    Button {
                        isShuffle.toggle()
                    } label: {
                        Image(systemName: "shuffle")
                            .font(.system(size: 20))
                            .foregroundColor(isShuffle ? Color(hex: "#1DB954") : .gray)
                    }
                    
                    Spacer()
                    
                    Button(action: onPrev) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                    
                    Button {
                        isPlaying.toggle()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 64, height: 64)
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.black)
                        }
                    }
                    
                    Button(action: onNext) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button {
                        repeatMode = (repeatMode + 1) % 3
                    } label: {
                        Image(systemName: repeatMode == 2 ? "repeat.1" : "repeat")
                            .font(.system(size: 20))
                            .foregroundColor(repeatMode > 0 ? Color(hex: "#1DB954") : .gray)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Bottom actions
                HStack {
                    Button {} label: {
                        Image(systemName: "tv")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button {} label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func timeString(seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Artwork View

struct ArtworkView: View {
    let imageName: String?
    let color: Color
    
    var body: some View {
        ZStack {
            if let imageName,
               !imageName.isEmpty,
               let uiImage = loadUIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Image(systemName: "music.note")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
    
    #if canImport(UIKit)
    private func loadUIImage(named: String) -> UIImage? {
        UIImage(named: named)
    }
    #else
    private func loadUIImage(named: String) -> Any? { nil }
    #endif
}

// MARK: - Models

struct Track: Identifiable, Equatable, Hashable {
    let id = UUID()
    let title: String
    let artist: String
    let color: Color
    let artworkImageName: String? // 放你的圖片名稱（Assets 中）
}

struct Playlist: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let subtitle: String
    let artworkColor: Color
    let tracks: [Track]
    let artworkImageName: String? // 放你的圖片名稱（Assets 中）
}

struct GenreTile: Identifiable {
    let id = UUID()
    let title: String
    let color: Color
}

enum SampleData {
    static let tracks: [Track] = [
        Track(title: "Blinding Lights", artist: "The Weeknd", color: Color(hex: "#8B4789"), artworkImageName: "tears"),
        Track(title: "Levitating", artist: "Dua Lipa", color: Color(hex: "#E13300"), artworkImageName: "dua"),
        Track(title: "Save Your Tears", artist: "The Weeknd", color: Color(hex: "#D84000"), artworkImageName: "tears"),
        Track(title: "Good 4 U", artist: "Olivia Rodrigo", color: Color(hex: "#8D67AB"), artworkImageName: "good4u"),
        Track(title: "Heat Waves", artist: "Glass Animals", color: Color(hex: "#5F8D4E"), artworkImageName: "heatwave"),
        Track(title: "Peaches", artist: "Justin Bieber", color: Color(hex: "#FF8C42"), artworkImageName: "justin"),
        Track(title: "Stay", artist: "The Kid LAROI", color: Color(hex: "#5C469C"), artworkImageName: "kid"),
        Track(title: "Butter", artist: "BTS", color: Color(hex: "#FFD23F"), artworkImageName: "bts")
    ]
    
    static let playlists: [Playlist] = [
        Playlist(name: "不講武德系列", subtitle: "The Weeknd、Post Malone 等", artworkColor: Color(hex: "#8B4789"), tracks: Array(tracks.shuffled().prefix(6)), artworkImageName: "kongming"),
        Playlist(name: "Daily Mix 2", subtitle: "Aespa, ILLIT, New Jeans 等", artworkColor: Color(hex: "#E13300"), tracks: Array(tracks.shuffled().prefix(6)), artworkImageName: "aespa"),
        Playlist(name: "Daily Mix 3", subtitle: "Ed Sheeran、Shawn Mendes 等", artworkColor: Color(hex: "#5F8D4E"), tracks: Array(tracks.shuffled().prefix(6)), artworkImageName: "edsheeran"),
        Playlist(name: "Top 50 songs", subtitle: "The hotest hits with Charlie path, Kelly Clarkson, Ariana Grande 等", artworkColor: Color(hex: "#1DB954"), tracks: Array(tracks.shuffled().prefix(6)), artworkImageName: "ariana"),
        Playlist(name: "Relax time", subtitle: "Katy Perry, Maroon 5, Dua Lipa 等", artworkColor: Color(hex: "#5C469C"), tracks: Array(tracks.shuffled().prefix(6)), artworkImageName: "run"),
        Playlist(name: "Focus", subtitle: "Radwimps, LISA, The Chainsmokers 等", artworkColor: Color(hex: "#2E86AB"), tracks: Array(tracks.shuffled().prefix(6)), artworkImageName: "lisa"),
        Playlist(name: "GYM", subtitle: "ILLIT, Daniel Powter, Halsey, Shawn Mendes 等", artworkColor: Color(hex: "#D84000"), tracks: Array(tracks.shuffled().prefix(6)), artworkImageName: "ILLIT"),
        Playlist(name: "Love", subtitle: "Eason One Republic, Taylor Swift, Sia等", artworkColor: Color(hex: "#8D67AB"), tracks: Array(tracks.shuffled().prefix(6)), artworkImageName: "eason")
    ]
    
    static let genres: [GenreTile] = [
        GenreTile(title: "流行音樂", color: Color(hex: "#8D67AB")),
        GenreTile(title: "嘻哈饒舌", color: Color(hex: "#E13300")),
        GenreTile(title: "搖滾", color: Color(hex: "#DC143C")),
        GenreTile(title: "拉丁音樂", color: Color(hex: "#FF6B35")),
        GenreTile(title: "電子舞曲", color: Color(hex: "#1DB954")),
        GenreTile(title: "Podcast", color: Color(hex: "#509BF5")),
        GenreTile(title: "華語流行", color: Color(hex: "#AF2BBF")),
        GenreTile(title: "心情放鬆", color: Color(hex: "#4ECDC4")),
        GenreTile(title: "K-Pop", color: Color(hex: "#FF006E")),
        GenreTile(title: "爵士樂", color: Color(hex: "#A64253"))
    ]
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}
