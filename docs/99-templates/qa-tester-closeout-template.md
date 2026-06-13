# QA Tester Closeout — [Tiêu đề]

> `qa-tester` điền và gửi lại Coordinator. Chỉ báo điều mà lệnh + artifact chứng minh.

1. **Outcome**: PASS | FAIL | BLOCKED | PREPARED
2. **Commands Run**:
   ```
   make test
   NEO_STOPMOTION_AUTOSHOOT=8 NEO_STOPMOTION_AUTOEXPORT=1 python -m neo_stopmotion
   ```
3. **Key Evidence**: [test counts, đường dẫn artifact, dòng log, QR/URL]
4. **Evidence Adjudication**: [vì sao chứng minh/không chứng minh expected result]
5. **False Positives Excluded**: [đã kiểm gì để tránh pass giả]
6. **Failure Classification**: infra/tooling · test-data · hardware/UART · camera · ffmpeg · upload/network · product · mixed
7. **Residual Risk / Follow-up**: [còn cần on-device / manual confirm gì]
