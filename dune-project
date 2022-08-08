(lang dune 2.7)
(name timed-cache)
(version 0.1.0)
(generate_opam_files true)
(license MIT)
(authors "Benjamin Somers <benjamin.somers@imt-atlantique.fr>")
(maintainers "Benjamin Somers <benjamin.somers@imt-atlantique.fr>")
(homepage "https://github.com/bensmrs/timed-cache")
(source (github "bensmrs/timed-cache"))
(bug_reports "https://github.com/bensmrs/timed-cache/issues")

(package
 (name timed-cache)
 (synopsis "UNIX-specific timed key-value store")
 (description "This package implements a key-value store where an expiration check is scheduled using SIGALRM signals")
 (depends
  (alcotest (>= 1.6.0))))
