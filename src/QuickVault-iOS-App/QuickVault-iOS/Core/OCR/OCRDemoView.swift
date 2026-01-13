import SwiftUI
import PhotosUI

struct OCRDemoView: View {
    @State private var pickerItem: PhotosPickerItem?
    @State private var result: DocumentExtractionResult?
    @State private var isLoading = false
    private let extractor = DocumentExtractor()

    var body: some View {
        VStack(spacing: 16) {
            PhotosPicker("选择证件照片", selection: $pickerItem, matching: .images)

            if isLoading { ProgressView() }

            if let r = result {
                Text("识别类型：\(r.docType.rawValue)")
                    .font(.headline)

                List(r.fields, id: \.self) { f in
                    HStack {
                        Text(f.label)
                        Spacer()
                        Text(f.value).foregroundStyle(.secondary)
                    }
                }

                // rawText 可用于 Debug
                DisclosureGroup("原始识别文本") {
                    Text(r.rawText).font(.footnote).textSelection(.enabled)
                }
            }
        }
        .padding()
        .task(id: pickerItem) {
            guard let pickerItem else { return }
            do {
                isLoading = true
                defer { isLoading = false }

                guard let data = try await pickerItem.loadTransferable(type: Data.self),
                      let img = UIImage(data: data) else { return }

                result = try await extractor.extract(from: img)
            } catch {
                isLoading = false
                print("OCR error:", error)
            }
        }
    }
}