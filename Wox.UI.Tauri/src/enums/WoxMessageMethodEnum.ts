import { BaseEnum } from "./base/BaseEnum.ts"

export class WoxMessageMethodEnum extends BaseEnum {
  static readonly PING = WoxMessageMethodEnum.define("Ping", "Ping")
  static readonly QUERY = WoxMessageMethodEnum.define("Query", "Query")
  static readonly ACTION = WoxMessageMethodEnum.define("Action", "Action")
  static readonly REFRESH = WoxMessageMethodEnum.define("Refresh", "Refresh")
  static readonly REGISTER_MAIN_HOTKEY = WoxMessageMethodEnum.define("RegisterMainHotkey", "Register Main Hotkey")
  static readonly ON_VISIBILITY_CHANGED = WoxMessageMethodEnum.define("OnVisibilityChanged", "Visibility changed")
}