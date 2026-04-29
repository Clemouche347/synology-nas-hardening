# SANDBOX ACL Verification Log

**Date:** 2026-04-01
**Command:**
```bash
for DIR in /volume1/SANDBOX/*/; do
  USERNAME=$(basename "$DIR")
  echo "=== $USERNAME ==="
  synoacltool -get "$DIR"
  echo ""
done
```

---

## Results

27 user subfolders verified. Each subfolder follows the same ACL pattern:

```
ACL version: 1
Archive: has_ACL,is_support_ACL
Owner: [admin(user)]
---------------------
  [0] group:administrators:allow:rwxpdDaARWc--:fd-- (level:0)
  [1] user:<username>:allow:rwxpdDaARWc--:fd-- (level:0)
```

### ACL flags breakdown

| Flag | Meaning |
|---|---|
| `r` | Read data |
| `w` | Write data |
| `x` | Execute/traverse |
| `p` | Append data |
| `d` | Delete child |
| `D` | Delete |
| `a` | Read attributes |
| `A` | Write attributes |
| `R` | Read ACL |
| `W` | Write ACL |
| `c` | Read owner |
| `fd` | Inherit to files and directories |

### Verification

- ✅ All 27 subfolders have exactly 2 ACL entries
- ✅ Entry [0]: `group:administrators` with full RW + inheritance
- ✅ Entry [1]: individual user with full RW + inheritance
- ✅ No parent inheritance — each subfolder is self-contained
- ✅ System folders (`#recycle`, `@eaDir`) correctly deny access
