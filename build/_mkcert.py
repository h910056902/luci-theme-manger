#!/usr/bin/env python3
"""为 uhttpd 生成自签 EC P-256 证书（SAN 覆盖路由器 IP / 域名 / localhost）。"""
import datetime
import ipaddress
import os

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.x509.oid import NameOID

OUT_DIR = os.path.dirname(os.path.abspath(__file__))

key = ec.generate_private_key(ec.SECP256R1())

subject = issuer = x509.Name([
    x509.NameAttribute(NameOID.COUNTRY_NAME, "CN"),
    x509.NameAttribute(NameOID.ORGANIZATION_NAME, "NRadio"),
    x509.NameAttribute(NameOID.COMMON_NAME, "192.168.66.1"),
])

san = x509.SubjectAlternativeName([
    x509.IPAddress(ipaddress.ip_address("192.168.66.1")),
    x509.IPAddress(ipaddress.ip_address("127.0.0.1")),
    x509.DNSName("nradio.in"),
    x509.DNSName("localhost"),
])

now = datetime.datetime.now(datetime.timezone.utc)
cert = (
    x509.CertificateBuilder()
    .subject_name(subject)
    .issuer_name(issuer)
    .public_key(key.public_key())
    .serial_number(x509.random_serial_number())
    .not_valid_before(now - datetime.timedelta(days=1))
    .not_valid_after(now + datetime.timedelta(days=3650))
    .add_extension(san, critical=False)
    .add_extension(x509.BasicConstraints(ca=False, path_length=None), critical=True)
    .add_extension(
        x509.KeyUsage(
            digital_signature=True, content_commitment=False,
            key_encipherment=False, data_encipherment=False,
            key_agreement=True, key_cert_sign=False, crl_sign=False,
            encipher_only=False, decipher_only=False,
        ),
        critical=True,
    )
    .add_extension(
        x509.ExtendedKeyUsage([x509.oid.ExtendedKeyUsageOID.SERVER_AUTH]),
        critical=False,
    )
    .sign(key, hashes.SHA256())
)

crt_path = os.path.join(OUT_DIR, "uhttpd.crt")
key_path = os.path.join(OUT_DIR, "uhttpd.key")

with open(crt_path, "wb") as f:
    f.write(cert.public_bytes(serialization.Encoding.PEM))

with open(key_path, "wb") as f:
    f.write(key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.TraditionalOpenSSL,
        encryption_algorithm=serialization.NoEncryption(),
    ))

print("cert ->", crt_path, os.path.getsize(crt_path), "bytes")
print("key  ->", key_path, os.path.getsize(key_path), "bytes")
print("subject:", cert.subject.rfc4514_string())
print("not_after:", cert.not_valid_after_utc.strftime("%Y-%m-%d"))
