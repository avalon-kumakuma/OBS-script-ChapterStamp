--[[

    Chapter Stamp
                Ver.0.9.0
]]


--[[
    グローバル変数
]]
obs = obslua

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
-- stats info
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
    スクリプトプロパティ表示用 ICONデータBASE64 引用元:いらすとや.
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



