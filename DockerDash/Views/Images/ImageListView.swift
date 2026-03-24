import SwiftUI

struct ImageListView: View {
    @State private var imageService = ImageService()
    @State private var searchText = ""

    private var filtered: [DockerImage] {
        if searchText.isEmpty { return imageService.images }
        return imageService.images.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Search images...", text: $searchText).textFieldStyle(.roundedBorder).frame(maxWidth: 300)
                Spacer()
                Button(action: { Task { await imageService.fetchImages() } }) {
                    Image(systemName: "arrow.clockwise")
                }.buttonStyle(.plain)
                Text("\(imageService.images.count) images").font(.caption).foregroundStyle(.secondary)
            }.padding(8)

            if imageService.isLoading && imageService.images.isEmpty {
                LoadingStateView()
            } else {
                List(filtered) { image in
                    HStack {
                        Image(systemName: "photo.stack").foregroundStyle(.purple)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(image.displayName).font(.body.weight(.medium)).lineLimit(1)
                            Text(image.shortId).font(.caption.monospaced()).foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Text(image.sizeFormatted).font(.caption).foregroundStyle(.secondary)
                        Text(image.createdDate.formatted(.relative(presentation: .named))).font(.caption2).foregroundStyle(.tertiary)
                    }
                    .contextMenu {
                        Button("Remove", role: .destructive) {
                            Task { try? await imageService.removeImage(image.id, force: true) }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Images")
        .task { await imageService.fetchImages() }
    }
}
