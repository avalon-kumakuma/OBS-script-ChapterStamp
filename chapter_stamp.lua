--[[

    Chapter Stamp
                Ver.0.9.0
]]

obs = obslua

--[[
    Safety OBS Studio version Check script Stop code start
]]
local obs_version = obs.obs_get_version()   -- Operating OBS version
local required_version = "30.0.0"           -- Required version

-- バージョンを比較するための関数
function version_is_lower_than(obs_version, required_version)
    local obs_major = bit.band(bit.rshift(obs_version, 24), 0xFF)
    local obs_minor = bit.band(bit.rshift(obs_version, 16), 0xFF)
    local obs_patch = bit.band(obs_version, 0xFFFF)
    local required_major, required_minor, required_patch = required_version:match("(%d+)%.(%d+)%.(%d+)")
    required_major = tonumber(required_major)
    required_minor = tonumber(required_minor)
    required_patch = tonumber(required_patch)
    if obs_major < required_major then
        return true
    elseif obs_major == required_major then
        if obs_minor < required_minor then
            return true
        elseif obs_minor == required_minor then
            if obs_patch < required_patch then
                return true
            end
        end
    end
    return false
end

-- version chekc
if version_is_lower_than(obs_version, required_version) then
    obs.script_log(obs.LOG_WARNING, "WARNING:Chapter Stamp Lua script STOP!!!, this OBS Studio version is not supported.")
    return
end
--[[
    Safety OBS Studio version Check script Stop code end
    
]]

-- グローバル変数
-- chapter_stamp.lua config
cstamp_cfg = {}
cstamp_cfg.version                 = "0.9.0"            -- Chapter Stamp ソフトウェアバージョン
cstamp_cfg.script_path             = script_path()      -- スクリプトパス
cstamp_cfg.hotkey_register_name    = "ChapterStamp_chkey_"      -- hotkey_register name
cstamp_cfg.beep_mediasource_name   = "STAMP_BEEP"       -- スタンプ時に再生するメディアソース名
cstamp_cfg.beep_file_name          = "STAMP_BEEP.wav"   -- メディアソースに利用するファイル名
cstamp_cfg.chapterfile_output_path = ""                 -- chapterファイル出力先
cstamp_cfg.chapterfile_name        = ""                 -- chapterファイル名形式
cstamp_cfg.chapterfile_open        = nil                -- ファイルハンドル
cstamp_cfg.repaly_stamp_file_name  = ""                 -- リプレイバッファスタンプのファイル名
cstamp_cfg.sshot_stamp_file_name   = ""                 -- スクリーンショットファイル名
cstamp_cfg.started_time            = nil                -- 開始時間 start time(second)
cstamp_cfg.previous_elapsed        = nil                -- 前回の経過時間 previous time(second)
cstamp_cfg.spacing_limit           = 10                 -- YouTube chapter spacing limit(second)
cstamp_cfg.logoutput_flg           = true               -- スプリクトログ出力フラグ
cstamp_cfg.logoutput_flg_dname     = "log_output_flg"
cstamp_cfg.logoutput_flg_sname     = "スプリクトログ 出力"
cstamp_cfg.logoutput_csv_flg       = false              -- コンマ区切り(CSV style)フラグ
cstamp_cfg.logoutput_csv_flg_dname = "log_output_csv_flg"
cstamp_cfg.logoutput_csv_flg_sname = "コンマ区切り(CSV)"

-- STAMP Output flg
stamp_flg = {}
stamp_flg.scene                 = false
stamp_flg.screenshot            = false
stamp_flg.replay                = false
stamp_flg.scene_dname           = "stamp_scene"
stamp_flg.screenshot_dname      = "stamp_screenshot"
stamp_flg.replay_dname          = "stamp_replay"
stamp_flg.scene_sname           = "STAMP出力：シーンチェンジ"
stamp_flg.screenshot_sname      = "STAMP出力：スクリーンショット"
stamp_flg.replay_sname          = "STAMP出力：リプレイバッファ"
stamp_flg.chotkey_max_number    = 2     -- カスタムホットキー最大数 1~5
stamp_flg.customhotkey          = {}    -- カスタムホットキー出力フラグ
stamp_flg.customhotkey_dname    = {}    -- stamp_customhotkey1~?
stamp_flg.customhotkey_sname    = {}    -- STAMP出力：カスタムホットキー1~?
stamp_flg.chotkey_label         = {}    -- カスタムホットキー出力 EventType名
stamp_flg.chotkey_dname_label   = {}    -- stamp_chotkey_label1~?
stamp_flg.chotkey_sname_label   = {}    -- ラベル：カスタムホットキー1~?"
for i = 1, stamp_flg.chotkey_max_number do
    stamp_flg.customhotkey[i] = false
end
for i = 1, stamp_flg.chotkey_max_number do
    stamp_flg.customhotkey_dname[i] = 
        "stamp_customhotkey" .. tostring(i)
end
for i = 1, stamp_flg.chotkey_max_number do
    stamp_flg.customhotkey_sname[i] = 
        "STAMP出力：カスタムホットキー " .. tostring(i)
end
for i = 1, stamp_flg.chotkey_max_number do
    stamp_flg.chotkey_label[i] = "CUSTOM_HOTKEY_" .. tostring(i)
end
for i = 1, stamp_flg.chotkey_max_number do
    stamp_flg.chotkey_dname_label[i] = 
        "stamp_chotkey_label" .. tostring(i)
end
for i = 1, stamp_flg.chotkey_max_number do
    stamp_flg.chotkey_sname_label[i] = 
        "出力イベント名："
end
if stamp_flg.chotkey_max_number > 5 then
    stamp_flg.chotkey_max_number = 5    -- 個数セーフティー
end

-- STAMP_BEEP play flg
pbeep_flg = {}
pbeep_flg.scene                 = false
pbeep_flg.screenshot            = false
pbeep_flg.replay                = false
pbeep_flg.scene_dname           = "beep_scene"
pbeep_flg.screenshot_dname      = "beep_screenshot"
pbeep_flg.replay_dname          = "beep_replay"
pbeep_flg.scene_sname           = "BEEP再生：シーンチェンジ"
pbeep_flg.screenshot_sname      = "BEEP再生：スクリーンショット"
pbeep_flg.replay_sname          = "BEEP再生：リプレイバッファ"
pbeep_flg.customhotkey          = {}    -- BEEP 再生フラグ
pbeep_flg.customhotkey_dname    = {}    -- beep_customhotkey1~?
pbeep_flg.customhotkey_sname    = {}    -- BEEP再生：カスタムホットキー1~?
for i = 1, stamp_flg.chotkey_max_number do
    pbeep_flg.customhotkey[i] = false
end
for i = 1, stamp_flg.chotkey_max_number do
    pbeep_flg.customhotkey_dname[i] = 
        "beep_customhotkey" .. tostring(i)
end
for i = 1, stamp_flg.chotkey_max_number do
    pbeep_flg.customhotkey_sname[i] = 
        "BEEP再生：カスタムホットキー " .. tostring(i)
end

-- CHAPTER STAMP CUSTOM HOTKEY
OBS_FRONTEND_EVENT_CUSTOMHOTKEY_BASE = 9990         -- OBS内部定数と競合の可能性あり
OBS_FRONTEND_EVENT_CUSTOMHOTKEY = {}    -- 9991~?   -- EVENT定数
for i = 1, stamp_flg.chotkey_max_number do
    OBS_FRONTEND_EVENT_CUSTOMHOTKEY[i] = 
        OBS_FRONTEND_EVENT_CUSTOMHOTKEY_BASE + i
end
hotkey_ids = {}
for i = 1, stamp_flg.chotkey_max_number do
    hotkey_ids[i] = obs.OBS_INVALID_HOTKEY_ID   -- ホットキーID
end

-- stats
OBS_FRONTEND_EVENT_STATS        = 99999         -- EVENT定数 OBS内部定数と競合の可能性あり
stats_output_flg                = false
stats_timer_id                  = nil           -- タイマーID
stats_sampling_interval         = 500           -- サンプリング間隔 ミリ秒 200~1000 100step
stats_output_flg_dname          = "stats_output_flg"
stats_output_flg_sname          = "統計情報 出力"
-- stats info Sampling Data
stats_info = {}
stats_info.last_bytes           = 0             -- 出力データ合計
stats_info.max_bitrate          = 0             -- 最大ビットレート
stats_info.min_bitrate          = math.huge     -- 最小ビットレート(最大数値で初期化)
stats_info.sum_bitrate          = 0             -- 合計ビットレート
stats_info.count                = 0             -- サンプリングカウント
stats_info.total_frames         = 0             -- 合計フレーム数
stats_info.dropped_frames       = 0             -- ドロップフレーム数(ネットワーク輻輳)

-- frontend profile settings
f_profile = {}                          -- 連想Key名＝iniファイル内の項目名
f_profile.Mode                  = ""    -- Output->Mode 出力モード 基本(Simple)/詳細(Advanced)
f_profile.FilenameFormatting    = ""    -- Output->FilenameFormatting 録画ファイル名フォーマット
f_profile.DelayEnable           = ""    -- Output->DelayEnable 遅延配信
f_profile.DelaySec              = ""    -- Output->DelaySec 期間(秒)
f_profile.DelayPreserve         = ""    -- Output->DelayPreserve 
                                        -- 再接続時にカットオフポイントを保持する(増加遅延)
f_profile.FilePath              = ""    -- SimpleOutput->FilePath 基本モードの録画パス
f_profile.RecRBPrefix           = ""    -- SimpleOutput->RecRBPrefix リプレイバッファ 接頭辞
f_profile.RecRBSuffix           = ""    -- SimpleOutput->RecRBSuffix リプレイバッファ 接尾辞
f_profile.RecType               = ""    -- AdvOut->RecType 録画の標準(Standard)/カスタム(FFmpeg)
f_profile.RecFilePath           = ""    -- AdvOut->RecFilePath 詳細モードの録画パス
f_profile.FFFilePath            = ""    -- AdvOut->FFFilePath カスタムFFmpeg時のパス

-- LOG Level
LOG_ERROR   = obs.LOG_ERROR   -- 100
LOG_WARNING = obs.LOG_WARNING -- 200
LOG_INFO    = obs.LOG_INFO    -- 300
LOG_DEBUG   = obs.LOG_DEBUG   -- 400

-- LOG output Level setting
log_lv      = LOG_INFO        -- release
-- log_lv      = LOG_DEBUG       -- debug



--[[
    ログ出力
        ログ出力フラグ log output flg対応
]]
function s_log(val1, val2)
    if cstamp_cfg.logoutput_flg == true then
        if val1 <= log_lv then
            obs.script_log(val1, val2)
        end
    end
end

--[[
    ファイル名フォーマット変換
    年:月:日:時:分:秒のみ変換可、後の書式は削除
    ※os.date()フォーマット、各OSの差異などある可能があり未検証
]]
function convert_filename_format(input)
    s_log(LOG_DEBUG, "convert_filename_format()")
    local format_mapping = {
        ["%%CCYY"] = "%%Y",     -- 年
        ["%%YY"]   = "%%Y",
        ["%%Y"]    = "%%Y",
        ["%%y"]    = "%%Y",
        ["%%MM"]   = "%%m",     -- 月
        ["%%m"]    = "%%m",
        ["%%b"]    = "%%m",
        ["%%B"]    = "%%m",
        ["%%DD"]   = "%%d",     -- 日
        ["%%d"]    = "%%d",
        ["%%hh"]   = "%%H",     -- 時
        ["%%H"]    = "%%H",
        ["%%I"]    = "%%H",
        ["%%mm"]   = "%%M",     -- 分
        ["%%M"]    = "%%M",
        ["%%ss"]   = "%%S",     -- 秒
        ["%%S"]    = "%%S",
        ["%%a"]    = "",        -- 曜日 略
        ["%%A"]    = "",        -- 曜日 完全
        ["%%p"]    = "",        -- 午前・午後
        ["%%s"]    = "",        -- UNIXエポック秒
        ["%%z"]    = "",        -- UTC 時差
        ["%%Z"]    = "",        -- タイムゾーン略称
        ["%%FPS"]  = "",        -- フレーム秒数
        ["%%CRES"] = "",        -- 基本(キャンバス)解像度
        ["%%ORES"] = "",        -- 出力(スケーリング)解像度
        ["%%VF"]   = ""         -- 映像フォーマット
    }
    for old_format, new_format in pairs(format_mapping) do
        input = input:gsub(old_format, new_format)
    end
    return input
end

--[[
    ファイルパスからファイル名取得
        "\"を"/"に変換後に、末尾から"/"の手前までを取得
]]
function extract_filename(filepath)
    s_log(LOG_DEBUG, "extract_filename():" .. filepath)

    if filepath ~= "" then
        local modified_filepath = filepath:gsub("\\\\", "/")
        local filename = modified_filepath:match("/([^/]-)$")
        return filename
    else
        s_log(LOG_DEBUG, "warning:filepath none")
        return ""
    end
end

--[[
    pathを整理
        pathに含まれる"\"を"/"置換
        lastslash_flgがtrueなら最後尾に"/"を追加、falseなら最後尾に"/"は無し
]]
function organize_path(path, lastslash_flg)
    s_log(LOG_DEBUG, "organize_path()")
    -- バックスラッシュをスラッシュに置換
    path = path:gsub([[\]], "/")
    -- lastslash_flgがtrueの場合、最後尾が"/"でなければスラッシュを追加
    if lastslash_flg == true then
        if path:sub(-1) ~= "/" then
            path = path .. "/"
        end
    -- lastslash_flgがfalseの場合、最後尾が"/"ならスラッシュを削除
    elseif lastslash_flg == false then
        if path:sub(-1) == "/" then
            path = path:sub(1, -2)
        end
    end
    return path
end

--[[
    chapter stamp 出力パス 設定
]]
function update_chapterfile_output_path()
    s_log(LOG_DEBUG, "update_chapterfile_output_path()")

    --[[
    -- プロファイルから取得
    get_frontend_profile_config_value()
    if f_profile.Mode == "Simple" then
        if obs.os_file_exists(organize_path(f_profile.FilePath, false)) then
            cstamp_cfg.chapterfile_output_path = organize_path(f_profile.FilePath, true)
        else
            cstamp_cfg.chapterfile_output_path = ""
        end
    else
        if f_profile.Mode == "Advanced"  then
            if f_profile.RecType == "Standard" then
                if obs.os_file_exists(organize_path(f_profile.RecFilePath, false)) then
                    cstamp_cfg.chapterfile_output_path = organize_path(f_profile.RecFilePath, 
                        true)
                else
                    cstamp_cfg.chapterfile_output_path = ""
                end
            else
                if f_profile.RecType == "FFmpeg" then
                    if obs.os_file_exists(organize_path(f_profile.FFFilePath, false)) then
                        cstamp_cfg.chapterfile_output_path = organize_path(f_profile.FFFilePath, 
                            true)
                    else
                        cstamp_cfg.chapterfile_output_path = ""
                    end
                end
            end
        end
    end
    ]]
    -- API利用
    local rec_path = obs.obs_frontend_get_current_record_output_path()
    if obs.os_file_exists(organize_path(rec_path, false)) then
        cstamp_cfg.chapterfile_output_path = organize_path(rec_path, true)
    else
        cstamp_cfg.chapterfile_output_path = ""
    end

    if cstamp_cfg.chapterfile_output_path == "" then   -- 例外処理
        -- デフォルト値取得 SimpleOutput->FilePath
        local cfg = obs.obs_frontend_get_profile_config()
        local cfg_value = obs.config_get_default_string(cfg, "SimpleOutput", "FilePath")
        if cfg_value ~= nil then
            if obs.os_file_exists(organize_path(cfg_value, false)) then
                cstamp_cfg.chapterfile_output_path = organize_path(cfg_value, true)
            else
                s_log(LOG_WARNING , "warning: Please set the recording path correctly.")
            end
        else
            s_log(LOG_WARNING , "warning: Please set the recording path correctly.")
        end
    end
end

--[[
    chapter_stamp.lua config値設定
]]
function update_chapter_stamp_config_value()
    s_log(LOG_DEBUG, "update_chapter_stamp_config_value()")

    -- chapter stamp 出力パス設定
    update_chapterfile_output_path()

    -- chapter stamp ファイル名生成
    cstamp_cfg.chapterfile_name = string.format("%s %s", 
        convert_filename_format(f_profile.FilenameFormatting), "Chapter_Stamp.txt")
    -- リプレイバッファ ファイル名フォーマット
    cstamp_cfg.repaly_stamp_file_name = string.format("%s %s %s", 
        f_profile.RecRBPrefix, convert_filename_format(f_profile.FilenameFormatting), 
        f_profile.RecRBSuffix)
    -- スクリーンショット ファイル名フォーマット
    cstamp_cfg.sshot_stamp_file_name = string.format("%s %s", 
        "Screenshot", convert_filename_format(f_profile.FilenameFormatting))

    -- debug code
        -- s_log(LOG_DEBUG, "cstamp_cfg-----")
        -- for key, value in pairs(cstamp_cfg) do
        --     print_table({[key] = value})
        -- end
end

--[[
    BEEP音ファイルチェック
]]
function beep_file_check()
    s_log(LOG_DEBUG, "beep_file_check()")

    if obs.os_file_exists(script_path() .. cstamp_cfg.beep_file_name) == true then
        s_log(LOG_DEBUG, cstamp_cfg.beep_file_name .. " OK")
        return true
    else
        s_log(LOG_WARNING, 
         "warning:" .. cstamp_cfg.beep_file_name .. " File does not exist in script path")
        return false
    end
    
end

--[[
    フロントエンド(カレント)プロファイルの設定値を取得
    ※basic.ini 内の設定値名には同一名が無いので正常に動作
]]
function get_frontend_profile_config_value()
    s_log(LOG_DEBUG, "get_frontend_profile_config_value()")

    local cfg = obs.obs_frontend_get_profile_config()
    local num_sections = obs.config_num_sections(cfg)

    for i = 0, num_sections-1, 1 do
        local sections_name = obs.config_get_section(cfg, i)
        local key   = ""
        local value = ""
        for key, value in pairs(f_profile) do
            local cfg_value = obs.config_get_string(cfg, sections_name, key)
            if cfg_value ~= nill then
                f_profile[key] = cfg_value
            end
        end
    end
    -- debug code
        -- s_log(LOG_DEBUG, "f_profile-----")
        -- for key, value in pairs(f_profile) do
        --     print_table({[key] = value})
        -- end
end 


--[[
    カスタムホットキー イベント
]]
function custom_hotkey_event(event)
    s_log(LOG_DEBUG, "custom_hotkey_event()")

    -- chapterstamp_frontend_event 集約
    chapterstamp_frontend_event(event)
end

--[[
    フロントエンド イベント
]]
function chapterstamp_frontend_event(event)
    s_log(LOG_DEBUG, "chapterstamp_frontend_event():" .. tostring(event))

    local event_time = os.time()    -- location考慮 os.time()採用
    if event_time <= 0 then
        s_log(LOG_WARNING, "warning:os.time()=%d", event_time)      -- 例外処理
        return
    end

    if event == obs.OBS_FRONTEND_EVENT_PROFILE_CHANGED 
     or event == obs.OBS_FRONTEND_EVENT_SCENE_COLLECTION_CHANGED then
        s_log(LOG_DEBUG, "PROFILE_CHANGING settings update")
        get_frontend_profile_config_value()     -- プロファイル各種情報取得
        update_chapter_stamp_config_value()     -- chapter_stamp.lua config値設定
    end
    if event == obs.OBS_FRONTEND_EVENT_STREAMING_STARTED
     or event == obs.OBS_FRONTEND_EVENT_RECORDING_STARTED
     or event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_STARTED then
        get_frontend_profile_config_value()     -- プロファイル各種情報取得
        update_chapter_stamp_config_value()     -- chapter_stamp.lua config値設定
        chapterstamp_started(event, event_time)
    end
    if event == obs.OBS_FRONTEND_EVENT_STREAMIN1G_STOPPED
     or event == obs.OBS_FRONTEND_EVENT_RECORDING_STOPPED
     or event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_STOPPED then
        chapterstamp_stopped(event, event_time)
    end
    if event == obs.OBS_FRONTEND_EVENT_SCENE_CHANGED then
        chapterstamp_event_check(event, event_time, 
            stamp_flg.scene, pbeep_flg.scene)
    end
    if event == obs.OBS_FRONTEND_EVENT_SCREENSHOT_TAKEN then
        chapterstamp_event_check(event, event_time, 
            stamp_flg.screenshot, pbeep_flg.screenshot)
    end
    if event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_SAVED then
        chapterstamp_event_check(event, event_time, 
            stamp_flg.replay, pbeep_flg.replay)
    end
    for i = 1, stamp_flg.chotkey_max_number do
        if event == OBS_FRONTEND_EVENT_CUSTOMHOTKEY[i] then
            chapterstamp_event_check(event, event_time, 
                stamp_flg.customhotkey[i], pbeep_flg.customhotkey[i])
        end
    end
end

--[[
    Chapter Stamp Output Chek
]]
function chapterstamp_event_check(event, event_time, stamp_flg, beep_flg)
    s_log(LOG_DEBUG, "chapterstamp_event_check()")

    -- Started Chek
    if cstamp_cfg.started_time == nil then
        s_log(LOG_DEBUG, "INFO:Chapter Stamp not started")
        return
    end
    if beep_flg == true then
        s_log(LOG_DEBUG, "BEEP Play")
        play_stamp_beep()
    end
    if stamp_flg == true then
        s_log(LOG_DEBUG, "Chapter Stamp")
        write_chapter_stamp(event, event_time)
    end
end

--[[
    Chapter Stamp Start
        配信開始/録画開始/リプレイバッファ開始
]]
function chapterstamp_started(event, event_time)
    s_log(LOG_DEBUG, "chapterstamp_started()")

    -- chapter stamp 動作中チェック
    if cstamp_cfg.started_time ~= nil then
        s_log(LOG_DEBUG, "Already started File opened")
        write_chapter_stamp(event, event_time)
        return
    end

    cstamp_cfg.started_time = event_time
    update_chapterfile_output_path()                -- 出力パス更新

    if cstamp_cfg.chapterfile_output_path ~= "" then
        filename = os.date(cstamp_cfg.chapterfile_name, cstamp_cfg.started_time)
        cstamp_cfg.chapterfile_open = io.open(cstamp_cfg.chapterfile_output_path .. filename, "w")
        if cstamp_cfg.chapterfile_open == nil then
            s_log(LOG_DEBUG, "The Chapter Stamp file could not be created.")
        else
            s_log(LOG_DEBUG, "io.output()")
            io.output(cstamp_cfg.chapterfile_open)
            -- CSV style 項目説明行追加
            if cstamp_cfg.logoutput_csv_flg == true then
                local line = "Timestamp,FrontendScene,EventType,FileName,URLQueryParameter"
                io.write(line, "\n")
                io.flush()              -- OBS クラッシュ対策
            end
        end
    else
        s_log(LOG_WARNING, "warning:chapterfile_output_path None")     -- 例外処理
    end

    -- stats
    if stats_output_flg == true then
        stats_info = {
            last_bytes = 0, 
            max_bitrate = 0, 
            min_bitrate = math.huge, 
            sum_bitrate = 0, 
            count = 0, 
            total_frames = 0, 
            dropped_frames = 0}
        -- 統計サンプリング タイマー登録
        obs.timer_add(stats_update_info, stats_sampling_interval)
    end

    write_chapter_stamp(event, 0)    -- 初回Start 0秒(00:00:00)

end


--[[
    Chapter Stamp Stop
        配信開始/録画開始/リプレイバッファ停止後
]]
function chapterstamp_stopped(event, event_time)
    s_log(LOG_DEBUG, "chapterstamp_stopped()")
    if cstamp_cfg.started_time == nil then
        s_log(LOG_WARNING, "warning:Chapter Stamp not started")
        return
    end

    -- 状態チェック 配信中/録画中/リプレイ中
    local active_check = false
    if obs.obs_frontend_streaming_active() == true then
        s_log(LOG_DEBUG, "active:streaming")
        active_check = true
    end
    if obs.obs_frontend_recording_active() == true then
        s_log(LOG_DEBUG, "active:recording")
        active_check = true
    end
    if obs.obs_frontend_replay_buffer_active() == true then
        s_log(LOG_DEBUG, "active:replay_buffer")
        active_check = true
    end

    write_chapter_stamp(event, event_time)
    if active_check == true then
        --[[ 配信開始/録画開始/リプレイバッファ
                いずれかが動作中なら 保持：ファイルオープン、各種時間
        ]]
        s_log(LOG_DEBUG, "active File Close & Start Reset abort")
        active_check = false        -- localだが念のため
        return
    end

    -- stats
    if stats_output_flg == true then
        -- 統計サンプリング タイマー登録
        obs.timer_remove(stats_update_info)
        --obs.remove_current_callback()
        -- 統計書込み
        write_chapter_stamp(OBS_FRONTEND_EVENT_STATS, event_time)
    end

    cstamp_cfg.started_time = nil
    cstamp_cfg.previous_elapsed  = nil

    if cstamp_cfg.chapterfile_open ~= "" then
        s_log(LOG_DEBUG, "io.close()")
        io.close()
        cstamp_cfg.chapterfile_open = nil
    end

end

--[[
    Chapter Stamp ライン書込み
]]
function write_chapter_stamp(event, event_time)
    s_log(LOG_DEBUG, "write_chapter_stamp()")

    local line           = ""        -- 出力ライン
    local diffime        = nil       -- 差分時間
    local schar          = " "       -- スペース文字 " " or ","
    local last_file_name = ""

    if event_time == 0 then          -- 初回スタート処理、差分$
        diffime = 0 
    else
        diffime = os.difftime(event_time, cstamp_cfg.started_time)
    end
    if cstamp_cfg.logoutput_csv_flg == true then
        schar = ","             -- CSV style
    else
        schar = " "
    end
    -- START
    if event == obs.OBS_FRONTEND_EVENT_STREAMING_STARTED then
        line = format_chapter_line(string.format("%s%s%s%s%s&t=%d", 
                get_current_sname(), schar, "-- STREAMING START --", schar, 
                schar, diffime), diffime)
    end
    if event == obs.OBS_FRONTEND_EVENT_RECORDING_STARTED then
        --[[
            last name API
        ]]
        last_file_name = extract_filename(obs.obs_frontend_get_last_recording())
        line = format_chapter_line(string.format("%s%s%s%s%s%s&t=%d", 
                get_current_sname(), schar, "-- RECORDING START --", schar, last_file_name, 
                schar, diffime), diffime)
        --[[
            None last name API  実際のファイル名とズレる
        ]]
        -- last_file_name = os.date(convert_filename_format(f_profile.FilenameFormatting), 
        --     cstamp_cfg.started_time)
        -- line = format_chapter_line(string.format("%s%s%s%s%s%s&t=%d", 
        --         get_current_sname(), schar, "-- RECORDING START --", schar, last_file_name, 
        --         schar, diffime), diffime)
    end
    if event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_STARTED then
        line = format_chapter_line(string.format("%s%s%s%s%s&t=%d", 
                get_current_sname(), schar, "-- REPLAY BUFFER START --", schar, 
                schar, diffime), diffime)
    end

    -- STOP
    if event == obs.OBS_FRONTEND_EVENT_STREAMING_STOPPED then
        line = format_chapter_line(string.format("%s%s%s%s%s&t=%d", 
                get_current_sname(), schar, "-- STREAMING STOP --", schar, 
                schar, diffime), diffime)
    end
    if event == obs.OBS_FRONTEND_EVENT_RECORDING_STOPPED then
        line = format_chapter_line(string.format("%s%s%s%s%s&t=%d", 
                get_current_sname(), schar, "-- RECORDING STOP --", schar, 
                schar, diffime), diffime)
    end
    if event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_STOPPED then
        line = format_chapter_line(string.format("%s%s%s%s%s&t=%d", 
                get_current_sname(), schar, "-- REPLAY BUFFER STOP --", schar, 
                schar, diffime), diffime)
    end
    -- stats
    if event == OBS_FRONTEND_EVENT_STATS then
        line = string.format("About Stats Information:%s%s\n", schar, os.date("%Y-%m-%d %H:%M:%S", event_time))
        line = line .. string.format("Sampling Count:%s%d\n", schar, stats_info.count)
        line = line .. string.format("Total Output Data(Not FileSize) :%s%.2f Mbytes\n", schar, (stats_info.last_bytes/1048576))
        local avg_bitrate = stats_info.sum_bitrate / stats_info.count
        line = line .. string.format("Average bitrate:%s%d kbps\n", schar, (avg_bitrate/1024))
        line = line .. string.format("Maximum bitrate:%s%d kbps\n", schar, (stats_info.max_bitrate/1024))
        if stats_info.count > 20 then
            line = line .. string.format("Minimum bitrate:%s%d kbps\n", schar, (stats_info.min_bitrate/1024))
        else
            line = line .. string.format(
                    "Minimum bitrate:%sUnable to measure due to small number of samples\n", schar)
        end
        local dropped_frame_rate = stats_info.dropped_frames / stats_info.total_frames * 100
        line = line .. string.format("Network Dropped frames:%s%d\n", schar, stats_info.dropped_frames)
        line = line .. string.format("Total frames:%s%d\n", schar, stats_info.total_frames)
        line = line .. string.format("Dropped frame rate:%s%3.2f%%\n", schar, dropped_frame_rate)
    end
    -- scene
    if event == obs.OBS_FRONTEND_EVENT_SCENE_CHANGED then
        line = format_chapter_line(string.format("%s%s%s%s%s&t=%d", 
            get_current_sname(), schar, "SCENE_CHANGE", schar, schar, diffime), diffime)
    end
    -- screenshot
    if event == obs.OBS_FRONTEND_EVENT_SCREENSHOT_TAKEN then
        -- last name API
        last_file_name = extract_filename(obs.obs_frontend_get_last_screenshot())
        line = format_chapter_line(string.format("%s%s%s%s%s%s&t=%d", 
            get_current_sname(), schar, "SCREENSHOT", schar, last_file_name, schar, 
            diffime), diffime)
        -- None last name API  実際のファイル名とズレる
        -- last_file_name = os.date(cstamp_cfg.sshot_stamp_file_name, event_time)
        -- line = format_chapter_line(string.format("%s%s%s%s%s%s&t=%d", 
        --     get_current_sname(), schar, "SCREENSHOT", schar, last_file_name, schar, 
        --     diffime), diffime)
    end
    -- replay buffer
    if event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_SAVED then
        -- last name API
        last_file_name = extract_filename(obs.obs_frontend_get_last_replay())
        line = format_chapter_line(string.format("%s%s%s%s%s%s&t=%d", 
            get_current_sname(), schar, "REPLAY BUFFER", schar, last_file_name, schar, 
            diffime), diffime)
        -- None last name API 実際のファイル名とズレる
        -- last_file_name = os.date(cstamp_cfg.repaly_stamp_file_name, event_time)
        -- line = format_chapter_line(string.format("%s%s%s%s%s%s&t=%d", 
        --     get_current_sname(), schar, "REPLAY BUFFER", schar, last_file_name, schar, 
        --     diffime), diffime)
    end
    -- custom hotkey
    for i = 1, stamp_flg.chotkey_max_number do
        if event == OBS_FRONTEND_EVENT_CUSTOMHOTKEY[i] then
            line = format_chapter_line(string.format("%s%s%s%s&t=%d", 
                get_current_sname(), schar, stamp_flg.chotkey_label[i], schar, diffime), diffime)
        end
    end

    local r = io.write(line, "\n")
    io.flush()         -- OBS クラッシュ対策で逐次書込み

    s_log(LOG_INFO, line)
end

--[[
    差分時間変換及び警告表示追加
]]
function format_chapter_line(output_line, diffime)
    s_log(LOG_DEBUG, "format_chapter_line():" .. tostring(diffime))

    local schar = " "       -- space" " or comma","
    if cstamp_cfg.logoutput_csv_flg == true then
        schar   = ","
    else
        schar   = " "
    end
    -- 差分時間変換
    local seconds = math.floor(diffime % 60)
    local minutes = math.floor((diffime / 60) % 60)
    local hours   = math.floor(diffime / 3600)
    local warning_sign = ""
    -- 警告表示
    if cstamp_cfg.previous_elapsed ~= nil then
        -- Youtube仕様対策 cstamp_cfg.spacing_limitより小さければ ＊付
        if (diffime - cstamp_cfg.previous_elapsed) < cstamp_cfg.spacing_limit then
            warning_sign = "*"
        end
    end

    cstamp_cfg.previous_elapsed = diffime
    return string.format("%s%02d:%02d:%02d%s%s", warning_sign, hours, minutes, seconds, 
               schar, output_line)
end

--[[
    フロントエンド(カレント)シーン名取得
]]
function get_current_sname()
    s_log(LOG_DEBUG, "get_current_sname()")
    local scene = obs.obs_frontend_get_current_scene()
    if scene == nil then
        s_log(LOG_WARNING, "warning:obs_frontend_get_current_scene() scene nil")
    end
    local scene_name = obs.obs_source_get_name(scene)
    if scene ~= nil then
        obs.obs_source_release(scene)
    end
    return scene_name
end

--[[
    メディアソース "STAMP_BEEP" 再開再生
]]
function play_stamp_beep()
    s_log(LOG_DEBUG, "play_stamp_beep()")

    local current_scene = obs.obs_frontend_get_current_scene()
    if current_scene ~= nil then
        local scene = obs.obs_scene_from_source(current_scene)
        if scene ~= nil then
            -- STAMP_BEEP
            local scene_item = obs.obs_scene_find_source(scene, cstamp_cfg.beep_mediasource_name)
            if scene_item ~= nil then
                local media_source = obs.obs_sceneitem_get_source(scene_item)
                if obs.obs_source_media_get_state(media_source) ~= obs.OBS_MEDIA_STATE_PLAYING then
                    obs.obs_source_media_restart(media_source)
                end
            else
                s_log(LOG_WARNING, "warning:obs_scene_find_source() scene_item nil")
            end
        else
            s_log(LOG_WARNING, "warning:obs_scene_from_source() scene nil")
        end
    else
        s_log(LOG_WARNING, "warning:obs_frontend_get_current_scene() current_scene nil")
    end

    if scene ~= nil then
        obs.obs_scene_release(scene)
    end
    if current_scene ~= nil then
        obs.obs_source_release(current_scene)
    end
end

--[[
    全てのシーンへ メディアソースSTAMP_BEEPを登録
        ・対象ファイル：script_path()内の"STAMP_BEEP.wav"
        ・ソースアクティブの再開再生をオフ
        ・各シーンの最下部にメディアソースを配置しロック
        ・オーディオの詳細プロパティ内 トラック設定を全てオフ
]]
function add_stamp_beep_all_scenes()
    s_log(LOG_DEBUG, "add_stamp_beep_all_scenes()")

    local scenes = obs.obs_frontend_get_scenes()
    local stamp_beep_source = obs.obs_get_source_by_name(cstamp_cfg.beep_mediasource_name)

    if stamp_beep_source == nil then
        -- メディア ソースが存在しない場合は作成
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "local_file", 
            organize_path(cstamp_cfg.script_path, true) .. cstamp_cfg.beep_file_name)
        obs.obs_data_set_bool(settings, "restart_on_activate", false)
        stamp_beep_source = obs.obs_source_create("ffmpeg_source", 
            cstamp_cfg.beep_mediasource_name, settings, nil)
        -- debug
        --  local track = obs.obs_source_get_audio_mixers(stamp_beep_source)
        --  s_log(LOG_DEBUG, "audio_mixers:" .. tostring(track))
        --[[
           Track    65 4321
           bit    0011 1111
        ]]
        obs.obs_source_set_audio_mixers(stamp_beep_source, 0)  -- 0=Track ALL OFF
        if settings ~= nil then
            obs.obs_data_release(settings)
        end
    end

    if scenes ~= nil then
        for _, scene in ipairs(scenes) do
            local duplicated_source = obs.obs_source_duplicate(stamp_beep_source, 
                cstamp_cfg.beep_mediasource_name, false)
            if duplicated_source ~= nil then
                local sceneitem = obs.obs_scene_add(obs.obs_scene_from_source(scene), 
                                    duplicated_source)
                if sceneitem ~= nil then
                    -- Move the item to the bottom
                    obs.obs_sceneitem_set_order(sceneitem, obs.OBS_ORDER_MOVE_BOTTOM)
                    -- Locked
                    obs.obs_sceneitem_set_locked(sceneitem, true)
                end
                obs.obs_source_release(duplicated_source)
            end
        end
    end

    if scenes ~= nil then
        obs.source_list_release(scenes)
    end
    if stamp_beep_source ~= nil then
        obs.obs_source_release(stamp_beep_source)
    end
end

--[[
    全てのシーンへ STAMP_BEEPを全て削除
]]
function remove_stamp_beep_all_scenes()
    s_log(LOG_DEBUG, "remove_stamp_beep_all_scenes()")

    local scenes = obs.obs_frontend_get_scenes()
    if scenes ~= nil then
        for _, scene in ipairs(scenes) do
            local sceneitems = obs.obs_scene_enum_items(obs.obs_scene_from_source(scene))
            if sceneitems ~= nil then
                for _, sceneitem in ipairs(sceneitems) do
                    local item_source = obs.obs_sceneitem_get_source(sceneitem)
                    if obs.obs_source_get_name(item_source) == cstamp_cfg.beep_mediasource_name then
                        obs.obs_sceneitem_remove(sceneitem)
                    end
                end
                obs.sceneitem_list_release(sceneitems)
            else
                s_log(LOG_WARNING, "obs_scene_enum_items() sceneitems nil")
            end
        end
        obs.source_list_release(scenes)
    else
        s_log(LOG_WARNING, "obs_frontend_get_scenes() scenes nil")
    end
end

--[[
    統計情報収集
        各ビットレート＆送信フレーム情報
]]
function stats_update_info()
    s_log(LOG_DEBUG, "stats_update_info()")

    if stats_output_flg == false then
        s_log(LOG_DEBUG, "stats_update_info(): stats_output_flg false")
        return
    end

    local output = obs.obs_frontend_get_streaming_output()
    if output == nil then
        output = obs.obs_frontend_get_recording_output()
    end
    if output ~= nil then
        local total_bytes = obs.obs_output_get_total_bytes(output)
        local total_frames = obs.obs_output_get_total_frames(output)
        local dropped_frames = obs.obs_output_get_frames_dropped(output)
        obs.obs_output_release(output)

        -- ビットレートを計算します（ビットレート = (バイト数 * 8) / 時間）
        -- 時間 1000 ms / Sampling Interval 200~1000 (Default 500)
        local bitrate = (total_bytes - stats_info.last_bytes) * 8 * (1000/stats_sampling_interval)
        stats_info.last_bytes = total_bytes

        -- ビットレート情報とフレーム情報を更新します
        stats_info.sum_bitrate = stats_info.sum_bitrate + bitrate
        stats_info.count = stats_info.count + 1
        stats_info.max_bitrate = math.max(stats_info.max_bitrate, bitrate)
        -- 初動の不安定な低ビットレートを排除 20サンプリング
        if stats_info.count > 20 then
            stats_info.min_bitrate = math.min(stats_info.min_bitrate, bitrate)
        end

        stats_info.total_frames = total_frames
        stats_info.dropped_frames = dropped_frames

        -- debug code
            s_log(LOG_DEBUG, "About Stats Information")
            s_log(LOG_DEBUG, string.format("Sampling Count: %d", stats_info.count))
            s_log(LOG_DEBUG, string.format("Total Output Data(Not FileSize): %.2f Mbytes", (stats_info.last_bytes/1048576)))
            local avg_bitrate = stats_info.sum_bitrate / stats_info.count
            s_log(LOG_DEBUG, string.format("Average bitrate: %d kbps", (avg_bitrate/1024)))
            s_log(LOG_DEBUG, string.format("Maximum bitrate: %d kbps", (stats_info.max_bitrate/1024)))
            s_log(LOG_DEBUG, string.format("Minimum bitrate: %d kbps", (stats_info.min_bitrate/1024)))
            local dropped_frame_rate = stats_info.dropped_frames / stats_info.total_frames * 100
            s_log(LOG_DEBUG, string.format("Network Dropped frames: %d", stats_info.dropped_frames))
            s_log(LOG_DEBUG, string.format("Total frames: %d", stats_info.total_frames))
            s_log(LOG_DEBUG, string.format("Dropped frame rate: %3.2f%%", dropped_frame_rate))
        
    end
end

--[[
    callback script_load(settings)
       スクリプトプロパティ 初回設定値登録＆ハンドラー登録
]]
function script_load(settings)
    s_log(LOG_DEBUG, "script_load()")

    -- イベント取得 登録
    obs.obs_frontend_add_event_callback(chapterstamp_frontend_event)

    -- hotkey loop
    for i = 1, stamp_flg.chotkey_max_number do
        -- Custom Hotkey 登録
        hotkey_ids[i] = obs.obs_hotkey_register_frontend(cstamp_cfg.hotkey_register_name .. i, 
            "Chapter Stamp カスタムホットキー " .. i, function(pressed)
            if not pressed then
                return
            end
            custom_hotkey_event(OBS_FRONTEND_EVENT_CUSTOMHOTKEY_BASE + i)
        end)
        -- ホットキーの設定を復元します
        local hotkey_save_array = obs.obs_data_get_array(settings, 
                                    cstamp_cfg.hotkey_register_name .. i)
        obs.obs_hotkey_load(hotkey_ids[i], hotkey_save_array)
        obs.obs_data_array_release(hotkey_save_array)
    end

end

--[[
    callback script_save(settings)
        スクリプトプロパティ設定 保存
]]
function script_save(settings)
    s_log(LOG_DEBUG, "script_save()")

    -- ホットキーの設定を保存
    for i = 1, stamp_flg.chotkey_max_number do
        local hotkey_save_array = obs.obs_hotkey_save(hotkey_ids[i])
        obs.obs_data_set_array(settings, cstamp_cfg.hotkey_register_name .. i, hotkey_save_array)
        obs.obs_data_array_release(hotkey_save_array)
    end

end

--[[
    callback script_unload()
        スクリプト 設定解除
]]
function script_unload()
    s_log(LOG_DEBUG, "script_unload()")
    -- Custom Hotkey解除
    for i = 1, stamp_flg.chotkey_max_number do
        obs.obs_hotkey_unregister(hotkey_ids[i])
    end
end

--[[
    callback script_update(settings)
        スクリプト プロパティ設定値 登録(取得)
]]
function script_update(settings)
    s_log(LOG_DEBUG, "script_update()")

    stamp_flg.scene         = obs.obs_data_get_bool(settings, stamp_flg.scene_dname)
    stamp_flg.screenshot    = obs.obs_data_get_bool(settings, stamp_flg.screenshot_dname)
    stamp_flg.replay        = obs.obs_data_get_bool(settings, stamp_flg.replay_dname)
    for i = 1, stamp_flg.chotkey_max_number do
        stamp_flg.customhotkey[i] = 
            obs.obs_data_get_bool(settings, stamp_flg.customhotkey_dname[i])
        stamp_flg.chotkey_label[i] = 
            obs.obs_data_get_string(settings, stamp_flg.chotkey_dname_label[i])
    end

    pbeep_flg.scene         = obs.obs_data_get_bool(settings, pbeep_flg.scene_dname)
    pbeep_flg.screenshot    = obs.obs_data_get_bool(settings, pbeep_flg.screenshot_dname)
    pbeep_flg.replay        = obs.obs_data_get_bool(settings, pbeep_flg.replay_dname)
    for i = 1, stamp_flg.chotkey_max_number do
        pbeep_flg.customhotkey[i] = 
            obs.obs_data_get_bool(settings, pbeep_flg.customhotkey_dname[i])
    end

    cstamp_cfg.logoutput_csv_flg = obs.obs_data_get_bool(settings, 
                                        cstamp_cfg.logoutput_csv_flg_dname)
    stats_output_flg = obs.obs_data_get_bool(settings, 
                                        stats_output_flg_dname)
    cstamp_cfg.logoutput_flg = obs.obs_data_get_bool(settings, 
                                        cstamp_cfg.logoutput_flg_dname)

    get_frontend_profile_config_value()     -- プロファイル各種情報取得
    beep_file_check()                       -- beepファイルチェック
    update_chapter_stamp_config_value()     -- chapter_stamp.lua config値設定

    -- debug code
        -- s_log(LOG_DEBUG, "cstamp_cfg-----")
        -- for key, value in pairs(cstamp_cfg) do
        --     print_table({[key] = value})
        -- end
        -- s_log(LOG_DEBUG, "f_profile-----")
        -- for key, value in pairs(f_profile) do
        --     print_table({[key] = value})
        -- end
        -- s_log(LOG_DEBUG, "stamp_flg-----")
        -- for key, value in pairs(stamp_flg) do
        --     print_table({[key] = value})
        -- end
        -- s_log(LOG_DEBUG, "pbeep_flg-----")
        -- for key, value in pairs(pbeep_flg) do
        --     print_table({[key] = value})
        -- end
end

--[[
    デバッグ用 テーブル展開 ログ出力
]]
function print_table(t, indent)
    indent = indent or ''
    for key, value in pairs(t) do
        if type(value) == "table" then
            s_log(LOG_DEBUG, indent .. key .. "：")
            print_table(value, indent .. '  ')
        else
            s_log(LOG_DEBUG, indent .. key .. "：" .. tostring(value))
        end
    end
end


--[[
    callback script_defaults(settings)
        初期値設定
]]
function script_defaults(settings)
    s_log(LOG_DEBUG, "script_defaults()")

    obs.obs_data_set_default_bool(settings, stamp_flg.scene_dname,         true)
    obs.obs_data_set_default_bool(settings, stamp_flg.screenshot_dname,    true)
    obs.obs_data_set_default_bool(settings, stamp_flg.replay_dname,        true)
    for i = 1, stamp_flg.chotkey_max_number do
        obs.obs_data_set_default_bool(settings, stamp_flg.customhotkey_dname[i], true)
        obs.obs_data_set_default_string(settings, stamp_flg.chotkey_dname_label[i], 
            -- "CUSTOM_HOTKEY_" .. tostring(i))    -- テキスト custom hotkey event名
            stamp_flg.chotkey_label[i])    -- テキスト custom hotkey event名
    end

    obs.obs_data_set_default_bool(settings, pbeep_flg.scene_dname,         true)
    obs.obs_data_set_default_bool(settings, pbeep_flg.screenshot_dname,    true)
    obs.obs_data_set_default_bool(settings, pbeep_flg.replay_dname,        true)
    for i = 1, stamp_flg.chotkey_max_number do
        obs.obs_data_set_default_bool(settings, pbeep_flg.customhotkey_dname[i], true)
    end

    obs.obs_data_set_default_bool(settings, cstamp_cfg.logoutput_csv_flg_dname, false)
    obs.obs_data_set_default_bool(settings, stats_output_flg_dname, false)
    obs.obs_data_set_default_bool(settings, cstamp_cfg.logoutput_flg_dname, true)

end

--[[
    callback script_properties()
        スプリクト プロパティ設定 登録
]]
function script_properties()
    s_log(LOG_DEBUG, "script_properties()")

    local props = obs.obs_properties_create()

    obs.obs_properties_add_bool(props, stamp_flg.scene_dname,      stamp_flg.scene_sname)
    obs.obs_properties_add_bool(props, stamp_flg.screenshot_dname, stamp_flg.screenshot_sname)
    obs.obs_properties_add_bool(props, stamp_flg.replay_dname,     stamp_flg.replay_sname)
    for i = 1, stamp_flg.chotkey_max_number do
        obs.obs_properties_add_bool(props, stamp_flg.customhotkey_dname[i], 
            stamp_flg.customhotkey_sname[i])
        obs.obs_properties_add_text(props, stamp_flg.chotkey_dname_label[i], 
            stamp_flg.chotkey_sname_label[i], obs.OBS_TEXT_DEFAULT)
    end

    obs.obs_properties_add_bool(props, pbeep_flg.scene_dname,        pbeep_flg.scene_sname)
    obs.obs_properties_add_bool(props, pbeep_flg.screenshot_dname,   pbeep_flg.screenshot_sname)
    obs.obs_properties_add_bool(props, pbeep_flg.replay_dname,       pbeep_flg.replay_sname)
    for i = 1, stamp_flg.chotkey_max_number do
        obs.obs_properties_add_bool(props, pbeep_flg.customhotkey_dname[i], 
            pbeep_flg.customhotkey_sname[i])
    end

    obs.obs_properties_add_bool(props, cstamp_cfg.logoutput_csv_flg_dname,  
        cstamp_cfg.logoutput_csv_flg_sname)
    obs.obs_properties_add_bool(props, stats_output_flg_dname,  
        stats_output_flg_sname)
    obs.obs_properties_add_bool(props, cstamp_cfg.logoutput_flg_dname,  
        cstamp_cfg.logoutput_flg_sname)

    -- STAMP_BEEP mediasource add/remove button
    obs.obs_properties_add_button(props, "add_stamp_beep_button", 
        "ALLシーン：STAMP_BEEPを登録", add_stamp_beep_all_scenes)
    obs.obs_properties_add_button(props, "remove_stamp_beep_button", 
        "ALLシーン：STAMP_BEEPを削除", remove_stamp_beep_all_scenes)

    return props
end


--[[
    スクリプトプロパティ表示用 BASE64 ICONデータ引用元:いらすとや.
]]
local icon1 = "data:image/png;base64,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"

--[[
    Chapter Stamp
        スクリプト説明
]]
local description = [[ 
<div name="title">
<center><img width=50 height=50 src='%s'/ > <font size=6>Chapter Stamp </font> Ver %s</center>
</div>
<div name="operating_environment" ><font size=2>
<b>【動作環境】</b><br/>
    Supported Minimum OBS Studio Ver 30<br/>
    Supported Platforms Windows
</font></div>
<div name="description" ><font size=2><br/>
テキストファイルにタイムスタンプ(YouTube チャプター形式)を記録し、同時にメディアソース(STAMP_BEEP)を再生します。<br/>
メディアソース再生は単一のトラックに録音する事で、動画編集の目印利用を想定しています。<br/>
<br/></font>
<font size=3><b>【タイムスタンプ＆BEEP再生 可能なタイミング】</b></font><br/>
配信中・録画中・リプレイバッファ中のシーンチェンジ・スクリーンショット取得・リプレイバッファ取得・カスタムホットキー押し<br/>
<font size=2><br/>
・チャプタータイムスタンプテキストは録画パスへ保存<br/>
・テキスト内容をコンマ区切りのCSV styleに変更可能<br/>
・設定機能：再生BEEP用メディアソースの追加・削除ボタン<br/>
※利用者がオーディオの詳細プロパティ及び録画設定での音声トラック指定設定が必要<br/>
</font>
</div>
<hr width=500 />
]]

--[[
    callback script_description()
        スプリクト説明登録
]]
function script_description()
    s_log(LOG_DEBUG, "script_description()")
    return string.format(description, icon1, cstamp_cfg.version)
    -- return "Get chapter timestamp for Youtube & play specific media sources at the same time"
end



