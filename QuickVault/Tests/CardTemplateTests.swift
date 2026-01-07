//
//  CardTemplateTests.swift
//  QuickVault Tests
//

import XCTest

@testable import QuickVault

final class CardTemplateTests: XCTestCase {

  // MARK: - Property 7: Address Format Contains Labels
  // Feature: quick-vault-macos, Property 7: Address Format Contains Labels

  func testAddressFormatContainsLabels() {
    // Given
    let fieldValues: [String: String] = [
      "recipient": "张三",
      "phone": "13800138000",
      "province": "北京市",
      "city": "海淀区",
      "district": "中关村",
      "address": "科技大厦101室",
      "postalCode": "100080",
      "notes": "请在工作日送达",
    ]

    // When
    let formatted = AddressTemplate.formatForCopy(fieldValues: fieldValues)

    // Then - verify all labels are present
    XCTAssertTrue(formatted.contains("收件人："), "Should contain recipient label")
    XCTAssertTrue(formatted.contains("手机号："), "Should contain phone label")
    XCTAssertTrue(formatted.contains("地址："), "Should contain address label")
    XCTAssertTrue(formatted.contains("邮编："), "Should contain postal code label")
    XCTAssertTrue(formatted.contains("备注："), "Should contain notes label")

    // Verify all values are present
    XCTAssertTrue(formatted.contains("张三"))
    XCTAssertTrue(formatted.contains("13800138000"))
    XCTAssertTrue(formatted.contains("北京市海淀区中关村科技大厦101室"))
    XCTAssertTrue(formatted.contains("100080"))
    XCTAssertTrue(formatted.contains("请在工作日送达"))
  }

  func testAddressFormatWithoutOptionalFields() {
    // Given - without postal code and notes
    let fieldValues: [String: String] = [
      "recipient": "李四",
      "phone": "13900139000",
      "province": "上海市",
      "city": "浦东新区",
      "district": "陆家嘴",
      "address": "金融大厦202室",
    ]

    // When
    let formatted = AddressTemplate.formatForCopy(fieldValues: fieldValues)

    // Then - should not contain optional field labels
    XCTAssertTrue(formatted.contains("收件人："))
    XCTAssertTrue(formatted.contains("手机号："))
    XCTAssertTrue(formatted.contains("地址："))
    XCTAssertFalse(formatted.contains("邮编："), "Should not show postal code label when empty")
    XCTAssertFalse(formatted.contains("备注："), "Should not show notes label when empty")
  }

  // MARK: - Property 10: Invoice Format Contains Labels
  // Feature: quick-vault-macos, Property 10: Invoice Format Contains Labels

  func testInvoiceFormatContainsLabels() {
    // Given
    let fieldValues: [String: String] = [
      "companyName": "北京科技有限公司",
      "taxId": "91110000MA01A1B2C3",
      "address": "北京市朝阳区建国路1号",
      "phone": "010-12345678",
      "bankName": "中国工商银行北京分行",
      "bankAccount": "1234567890123456789",
      "notes": "增值税专用发票",
    ]

    // When
    let formatted = InvoiceTemplate.formatForCopy(fieldValues: fieldValues)

    // Then - verify all labels are present
    XCTAssertTrue(formatted.contains("公司名称："), "Should contain company name label")
    XCTAssertTrue(formatted.contains("税号："), "Should contain tax ID label")
    XCTAssertTrue(formatted.contains("地址："), "Should contain address label")
    XCTAssertTrue(formatted.contains("电话："), "Should contain phone label")
    XCTAssertTrue(formatted.contains("开户行："), "Should contain bank name label")
    XCTAssertTrue(formatted.contains("账号："), "Should contain bank account label")
    XCTAssertTrue(formatted.contains("备注："), "Should contain notes label")

    // Verify all values are present
    XCTAssertTrue(formatted.contains("北京科技有限公司"))
    XCTAssertTrue(formatted.contains("91110000MA01A1B2C3"))
    XCTAssertTrue(formatted.contains("增值税专用发票"))
  }

  func testInvoiceFormatWithoutOptionalNotes() {
    // Given - without notes
    let fieldValues: [String: String] = [
      "companyName": "上海贸易公司",
      "taxId": "91310000MA02B3C4D5",
      "address": "上海市黄浦区南京路2号",
      "phone": "021-87654321",
      "bankName": "中国建设银行上海分行",
      "bankAccount": "9876543210987654321",
    ]

    // When
    let formatted = InvoiceTemplate.formatForCopy(fieldValues: fieldValues)

    // Then - should not contain notes label
    XCTAssertTrue(formatted.contains("公司名称："))
    XCTAssertTrue(formatted.contains("税号："))
    XCTAssertFalse(formatted.contains("备注："), "Should not show notes label when empty")
  }

  // MARK: - Property 13: General Text Copy Direct
  // Feature: quick-vault-macos, Property 13: General Text Copy Direct

  func testGeneralTextCopyDirect() {
    // Given
    let content = "这是一段测试文本\n包含多行\n和中文字符"
    let fieldValues = ["content": content]

    // When
    let formatted = GeneralTextTemplate.formatForCopy(fieldValues: fieldValues)

    // Then - should return content directly without any labels
    XCTAssertEqual(formatted, content, "Should return content directly")
    XCTAssertFalse(formatted.contains("内容："), "Should not contain label")
  }

  func testGeneralTextPreservesNewlines() {
    // Given
    let content = "Line 1\nLine 2\nLine 3"
    let fieldValues = ["content": content]

    // When
    let formatted = GeneralTextTemplate.formatForCopy(fieldValues: fieldValues)

    // Then
    XCTAssertEqual(formatted, content)
    XCTAssertTrue(formatted.contains("\n"), "Should preserve newlines")
  }

  // MARK: - Template Helper Tests

  func testTemplateHelperFieldsForType() {
    // General
    let generalFields = CardTemplateHelper.fields(for: .general)
    XCTAssertEqual(generalFields.count, 1)
    XCTAssertEqual(generalFields[0].key, "content")

    // Address
    let addressFields = CardTemplateHelper.fields(for: .address)
    XCTAssertEqual(addressFields.count, 8)
    XCTAssertTrue(addressFields.contains { $0.key == "recipient" })
    XCTAssertTrue(addressFields.contains { $0.key == "phone" })

    // Invoice
    let invoiceFields = CardTemplateHelper.fields(for: .invoice)
    XCTAssertEqual(invoiceFields.count, 7)
    XCTAssertTrue(invoiceFields.contains { $0.key == "companyName" })
    XCTAssertTrue(invoiceFields.contains { $0.key == "taxId" })
  }

  func testTemplateHelperFormatForCopy() {
    // Test that helper delegates to correct template

    // General
    let generalValues = ["content": "Test content"]
    let generalFormatted = CardTemplateHelper.formatForCopy(
      type: .general, fieldValues: generalValues)
    XCTAssertEqual(generalFormatted, "Test content")

    // Address
    let addressValues = [
      "recipient": "测试",
      "phone": "13800138000",
      "province": "北京",
      "city": "海淀",
      "district": "中关村",
      "address": "1号",
    ]
    let addressFormatted = CardTemplateHelper.formatForCopy(
      type: .address, fieldValues: addressValues)
    XCTAssertTrue(addressFormatted.contains("收件人："))

    // Invoice
    let invoiceValues = [
      "companyName": "测试公司",
      "taxId": "123456789012345678",
      "address": "测试地址",
      "phone": "010-12345678",
      "bankName": "测试银行",
      "bankAccount": "123456",
    ]
    let invoiceFormatted = CardTemplateHelper.formatForCopy(
      type: .invoice, fieldValues: invoiceValues)
    XCTAssertTrue(invoiceFormatted.contains("公司名称："))
  }

  func testAddressFieldRequirements() {
    let fields = AddressTemplate.fields

    // Required fields
    XCTAssertTrue(fields.first { $0.key == "recipient" }?.required == true)
    XCTAssertTrue(fields.first { $0.key == "phone" }?.required == true)
    XCTAssertTrue(fields.first { $0.key == "province" }?.required == true)
    XCTAssertTrue(fields.first { $0.key == "city" }?.required == true)
    XCTAssertTrue(fields.first { $0.key == "district" }?.required == true)
    XCTAssertTrue(fields.first { $0.key == "address" }?.required == true)

    // Optional fields
    XCTAssertTrue(fields.first { $0.key == "postalCode" }?.required == false)
    XCTAssertTrue(fields.first { $0.key == "notes" }?.required == false)
  }

  func testInvoiceFieldRequirements() {
    let fields = InvoiceTemplate.fields

    // Required fields
    XCTAssertTrue(fields.first { $0.key == "companyName" }?.required == true)
    XCTAssertTrue(fields.first { $0.key == "taxId" }?.required == true)
    XCTAssertTrue(fields.first { $0.key == "address" }?.required == true)
    XCTAssertTrue(fields.first { $0.key == "phone" }?.required == true)
    XCTAssertTrue(fields.first { $0.key == "bankName" }?.required == true)
    XCTAssertTrue(fields.first { $0.key == "bankAccount" }?.required == true)

    // Optional fields
    XCTAssertTrue(fields.first { $0.key == "notes" }?.required == false)
  }
}
