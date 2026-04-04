// localize_phonenumber_nif.cpp
//
// Erlang NIF bindings to Google's libphonenumber C++ library.
// Provides phone number parsing, formatting, validation, type
// detection, and territory resolution.

#include <string>
#include <cstring>

#include "erl_nif.h"

#include "phonenumbers/phonenumberutil.h"
#include "phonenumbers/phonenumber.pb.h"
using i18n::phonenumbers::PhoneNumber;
using i18n::phonenumbers::PhoneNumberUtil;

// ── Cached atoms ────────────────────────────────────────────────

static ERL_NIF_TERM atom_ok;
static ERL_NIF_TERM atom_error;
static ERL_NIF_TERM atom_true;
static ERL_NIF_TERM atom_false;

// ── Helpers ─────────────────────────────────────────────────────

// Extract a std::string from an Erlang binary term.
static bool get_binary_string(ErlNifEnv* env, ERL_NIF_TERM term,
                              std::string& out) {
    ErlNifBinary bin;
    if (!enif_inspect_binary(env, term, &bin)) {
        return false;
    }
    out.assign(reinterpret_cast<const char*>(bin.data), bin.size);
    return true;
}

// Create an Erlang binary term from a std::string.
static ERL_NIF_TERM make_binary_string(ErlNifEnv* env,
                                       const std::string& str) {
    ERL_NIF_TERM bin;
    unsigned char* data = enif_make_new_binary(env, str.size(), &bin);
    std::memcpy(data, str.data(), str.size());
    return bin;
}

// Reconstruct a PhoneNumber from a serialized protobuf binary.
static bool deserialize_phone_number(ErlNifEnv* env, ERL_NIF_TERM term,
                                     PhoneNumber& phone_number) {
    std::string serialized;
    if (!get_binary_string(env, term, serialized)) {
        return false;
    }
    return phone_number.ParseFromString(serialized);
}

// Map PhoneNumberUtil::PhoneNumberType enum to a string.
static const char* phone_number_type_to_string(
    PhoneNumberUtil::PhoneNumberType type) {
    switch (type) {
        case PhoneNumberUtil::FIXED_LINE:           return "fixed_line";
        case PhoneNumberUtil::MOBILE:               return "mobile";
        case PhoneNumberUtil::FIXED_LINE_OR_MOBILE: return "fixed_line_or_mobile";
        case PhoneNumberUtil::TOLL_FREE:            return "toll_free";
        case PhoneNumberUtil::PREMIUM_RATE:         return "premium_rate";
        case PhoneNumberUtil::SHARED_COST:          return "shared_cost";
        case PhoneNumberUtil::VOIP:                 return "voip";
        case PhoneNumberUtil::PERSONAL_NUMBER:      return "personal_number";
        case PhoneNumberUtil::PAGER:                return "pager";
        case PhoneNumberUtil::UAN:                  return "uan";
        case PhoneNumberUtil::VOICEMAIL:            return "voicemail";
        default:                                    return "unknown";
    }
}

// Map PhoneNumberUtil::ErrorType to a human-readable string.
static const char* error_type_to_string(
    PhoneNumberUtil::ErrorType error) {
    switch (error) {
        case PhoneNumberUtil::INVALID_COUNTRY_CODE_ERROR:
            return "invalid_country_code";
        case PhoneNumberUtil::NOT_A_NUMBER:
            return "not_a_number";
        case PhoneNumberUtil::TOO_SHORT_AFTER_IDD:
            return "too_short_after_idd";
        case PhoneNumberUtil::TOO_SHORT_NSN:
            return "too_short";
        case PhoneNumberUtil::TOO_LONG_NSN:
            return "too_long";
        default:
            return "parse_error";
    }
}

// Map format type string to PhoneNumberUtil::PhoneNumberFormat enum.
static bool format_string_to_enum(const std::string& format_str,
                                  PhoneNumberUtil::PhoneNumberFormat& format) {
    if (format_str == "e164") {
        format = PhoneNumberUtil::E164;
    } else if (format_str == "international") {
        format = PhoneNumberUtil::INTERNATIONAL;
    } else if (format_str == "national") {
        format = PhoneNumberUtil::NATIONAL;
    } else if (format_str == "rfc3966") {
        format = PhoneNumberUtil::RFC3966;
    } else {
        return false;
    }
    return true;
}

// ── NIF functions ───────────────────────────────────────────────

// nif_parse(number_string, default_territory)
// -> {:ok, country_code, national_number, extension, raw_input, native_binary}
// -> {:error, reason}
static ERL_NIF_TERM nif_parse(ErlNifEnv* env, int argc,
                              const ERL_NIF_TERM argv[]) {
    std::string number_string;
    std::string default_territory;

    if (!get_binary_string(env, argv[0], number_string) ||
        !get_binary_string(env, argv[1], default_territory)) {
        return enif_make_badarg(env);
    }

    const PhoneNumberUtil* util = PhoneNumberUtil::GetInstance();
    PhoneNumber phone_number;

    PhoneNumberUtil::ErrorType error =
        util->ParseAndKeepRawInput(number_string, default_territory,
                                   &phone_number);

    if (error != PhoneNumberUtil::NO_PARSING_ERROR) {
        return enif_make_tuple2(
            env, atom_error,
            make_binary_string(env, error_type_to_string(error)));
    }

    // Serialize the full PhoneNumber proto for lossless round-trips.
    std::string serialized;
    (void)phone_number.SerializeToString(&serialized);

    // Extract fields for the Elixir struct.
    ERL_NIF_TERM country_code =
        enif_make_int(env, phone_number.country_code());
    ERL_NIF_TERM national_number =
        enif_make_uint64(env, phone_number.national_number());

    std::string ext = phone_number.has_extension()
                          ? phone_number.extension()
                          : "";
    ERL_NIF_TERM extension = make_binary_string(env, ext);

    std::string raw = phone_number.has_raw_input()
                          ? phone_number.raw_input()
                          : number_string;
    ERL_NIF_TERM raw_input = make_binary_string(env, raw);

    ERL_NIF_TERM native_binary = make_binary_string(env, serialized);

    return enif_make_tuple(env, 6, atom_ok, country_code,
                           national_number, extension, raw_input,
                           native_binary);
}

// nif_format(native_binary, format_type_string)
// -> {:ok, formatted_string}
// -> {:error, reason}
static ERL_NIF_TERM nif_format(ErlNifEnv* env, int argc,
                               const ERL_NIF_TERM argv[]) {
    PhoneNumber phone_number;
    if (!deserialize_phone_number(env, argv[0], phone_number)) {
        return enif_make_tuple2(
            env, atom_error,
            make_binary_string(env, "invalid_phone_number"));
    }

    std::string format_str;
    if (!get_binary_string(env, argv[1], format_str)) {
        return enif_make_badarg(env);
    }

    PhoneNumberUtil::PhoneNumberFormat format;
    if (!format_string_to_enum(format_str, format)) {
        return enif_make_tuple2(
            env, atom_error,
            make_binary_string(env, "invalid_format_type"));
    }

    const PhoneNumberUtil* util = PhoneNumberUtil::GetInstance();
    std::string formatted;
    util->Format(phone_number, format, &formatted);

    return enif_make_tuple2(env, atom_ok,
                            make_binary_string(env, formatted));
}

// nif_valid(native_binary) -> true | false
static ERL_NIF_TERM nif_valid(ErlNifEnv* env, int argc,
                              const ERL_NIF_TERM argv[]) {
    PhoneNumber phone_number;
    if (!deserialize_phone_number(env, argv[0], phone_number)) {
        return atom_false;
    }

    const PhoneNumberUtil* util = PhoneNumberUtil::GetInstance();
    return util->IsValidNumber(phone_number) ? atom_true : atom_false;
}

// nif_valid_for_territory(native_binary, territory) -> true | false
static ERL_NIF_TERM nif_valid_for_territory(ErlNifEnv* env, int argc,
                                            const ERL_NIF_TERM argv[]) {
    PhoneNumber phone_number;
    if (!deserialize_phone_number(env, argv[0], phone_number)) {
        return atom_false;
    }

    std::string territory;
    if (!get_binary_string(env, argv[1], territory)) {
        return enif_make_badarg(env);
    }

    const PhoneNumberUtil* util = PhoneNumberUtil::GetInstance();
    return util->IsValidNumberForRegion(phone_number, territory)
               ? atom_true
               : atom_false;
}

// nif_possible(native_binary) -> true | false
static ERL_NIF_TERM nif_possible(ErlNifEnv* env, int argc,
                                 const ERL_NIF_TERM argv[]) {
    PhoneNumber phone_number;
    if (!deserialize_phone_number(env, argv[0], phone_number)) {
        return atom_false;
    }

    const PhoneNumberUtil* util = PhoneNumberUtil::GetInstance();
    return util->IsPossibleNumber(phone_number) ? atom_true : atom_false;
}

// nif_type(native_binary) -> type_string
static ERL_NIF_TERM nif_type(ErlNifEnv* env, int argc,
                             const ERL_NIF_TERM argv[]) {
    PhoneNumber phone_number;
    if (!deserialize_phone_number(env, argv[0], phone_number)) {
        return make_binary_string(env, "unknown");
    }

    const PhoneNumberUtil* util = PhoneNumberUtil::GetInstance();
    PhoneNumberUtil::PhoneNumberType type =
        util->GetNumberType(phone_number);

    return make_binary_string(env, phone_number_type_to_string(type));
}

// nif_territory(native_binary) -> territory_string
static ERL_NIF_TERM nif_territory(ErlNifEnv* env, int argc,
                                  const ERL_NIF_TERM argv[]) {
    PhoneNumber phone_number;
    if (!deserialize_phone_number(env, argv[0], phone_number)) {
        return make_binary_string(env, "");
    }

    const PhoneNumberUtil* util = PhoneNumberUtil::GetInstance();
    std::string region_code;
    util->GetRegionCodeForNumber(phone_number, &region_code);

    // libphonenumber returns "ZZ" for unknown regions.
    if (region_code == "ZZ" || region_code.empty()) {
        return make_binary_string(env, "");
    }

    return make_binary_string(env, region_code);
}

// ── Lifecycle callbacks ─────────────────────────────────────────

static int on_load(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM info) {
    atom_ok    = enif_make_atom(env, "ok");
    atom_error = enif_make_atom(env, "error");
    atom_true  = enif_make_atom(env, "true");
    atom_false = enif_make_atom(env, "false");

    // Warm up the PhoneNumberUtil singleton. This loads the metadata
    // once so that subsequent calls are fast.
    PhoneNumberUtil::GetInstance();

    *priv_data = nullptr;
    return 0;
}

static void on_unload(ErlNifEnv* env, void* priv_data) {
    // Nothing to clean up. PhoneNumberUtil is a process-global singleton.
}

static int on_upgrade(ErlNifEnv* env, void** priv_data,
                      void** old_priv_data, ERL_NIF_TERM info) {
    *priv_data = nullptr;
    return 0;
}

// ── NIF function table ──────────────────────────────────────────

static ErlNifFunc nif_funcs[] = {
    {"nif_parse",                2, nif_parse},
    {"nif_format",               2, nif_format},
    {"nif_valid",                1, nif_valid},
    {"nif_valid_for_territory",  2, nif_valid_for_territory},
    {"nif_possible",             1, nif_possible},
    {"nif_type",                 1, nif_type},
    {"nif_territory",            1, nif_territory}
};

ERL_NIF_INIT(Elixir.LocalizePhonenumber.Nif, nif_funcs, &on_load,
             nullptr, &on_upgrade, &on_unload)
