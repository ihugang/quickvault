import SwiftUI
import PhotosUI

/// OCR 功能演示视图 / OCR Demo View
struct OCRDemoView: View {
    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var result: DocumentExtractionResult?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let extractor = DocumentExtractor()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 图片选择器
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    VStack(spacing: 12) {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(12)
                        } else {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 50))
                                .foregroundStyle(.secondary)
                            
                            Text("选择证件照片 / Select Document Photo")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 200)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // 加载状态
                if isLoading {
                    ProgressView("识别中... / Processing...")
                        .padding()
                }
                
                // 错误信息
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
                
                // 识别结果
                if let r = result {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // 文档类型
                            HStack {
                                Text("识别类型 / Document Type:")
                                    .font(.headline)
                                Spacer()
                                Text(r.docType.displayName)
                                    .font(.headline)
                                    .foregroundStyle(.blue)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            
                            // 字段列表
                            VStack(alignment: .leading, spacing: 12) {
                                Text("识别字段 / Extracted Fields")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(r.fields, id: \.label) { field in
                                    HStack(alignment: .top) {
                                        Text(field.label)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .frame(width: 120, alignment: .leading)
                                        
                                        Text(field.value)
                                            .font(.body)
                                            .textSelection(.enabled)
                                        
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(8)
                                }
                            }
                            
                            // 原始识别文本
                            DisclosureGroup("原始识别文本 / Raw Text") {
                                Text(r.rawText)
                                    .font(.footnote)
                                    .textSelection(.enabled)
                                    .padding()
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                        }
                        .padding()
                    }
                }
                
                Spacer()
            }
            .padding(.vertical)
            .navigationTitle("OCR 测试 / OCR Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task(id: pickerItem) {
            guard let pickerItem else { return }
            do {
                isLoading = true
                errorMessage = nil
                defer { isLoading = false }

                guard let data = try await pickerItem.loadTransferable(type: Data.self),
                      let img = UIImage(data: data) else {
                    errorMessage = "无法加载图片 / Failed to load image"
                    return
                }
                
                selectedImage = img
                result = try await extractor.extract(from: img)
            } catch {
                isLoading = false
                errorMessage = "识别失败: \(error.localizedDescription) / OCR failed"
                print("OCR error:", error)
            }
        }
    }
}

extension DocumentType {
    var displayName: String {
        switch self {
        case .idCard: return "身份证 / ID Card"
        case .passport: return "护照 / Passport"
        case .driversLicense: return "驾驶证 / Driver's License"
        case .businessLicense: return "营业执照 / Business License"
        case .residencePermit: return "居留许可 / Residence Permit"
        case .socialSecurityCard: return "社保卡 / Social Security Card"
        case .bankCard: return "银行卡 / Bank Card"
        case .general: return "通用文档 / General Document"
        }
    }
}
