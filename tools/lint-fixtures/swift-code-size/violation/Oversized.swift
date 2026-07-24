// Oversized.swift — deliberately trips ALL FIVE code-size rules at their
// warning thresholds. GENERATED WRITE-ONCE for check-lint-fragments.sh and
// never hand-edited: the fragment ships its real thresholds (fragment ==
// shipped config), so the only honest violation fixture for file_length/
// type_body_length is a genuinely oversized file.

import Foundation

// function_parameter_count: 6 > warning threshold 5
func tooManyParameters(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) -> Int {
    a + b + c + d + e + f
}

// cyclomatic_complexity: 13 > 10 AND function_body_length: 56 lines > 50
func branchyAndLong(value: Int) -> Int {
    if value == 0 {
        return 0
    }
    if value == 1 {
        return 10
    }
    if value == 2 {
        return 20
    }
    if value == 3 {
        return 30
    }
    if value == 4 {
        return 40
    }
    if value == 5 {
        return 50
    }
    if value == 6 {
        return 60
    }
    if value == 7 {
        return 70
    }
    if value == 8 {
        return 80
    }
    if value == 9 {
        return 90
    }
    if value == 10 {
        return 100
    }
    if value == 11 {
        return 110
    }
    let pad0 = value &+ 0
    let pad1 = value &+ 1
    let pad2 = value &+ 2
    let pad3 = value &+ 3
    let pad4 = value &+ 4
    let pad5 = value &+ 5
    let pad6 = value &+ 6
    let pad7 = value &+ 7
    let pad8 = value &+ 8
    let pad9 = value &+ 9
    let pad10 = value &+ 10
    let pad11 = value &+ 11
    let pad12 = value &+ 12
    let pad13 = value &+ 13
    let pad14 = value &+ 14
    let pad15 = value &+ 15
    let pad16 = value &+ 16
    let pad17 = value &+ 17
    return pad0 &+ pad1 &+ pad2 &+ pad3 &+ pad4 &+ pad5 &+ pad6 &+ pad7 &+ pad8 &+ pad9 &+ pad10 &+ pad11 &+ pad12 &+ pad13 &+ pad14 &+ pad15 &+ pad16 &+ pad17
}

// type_body_length: 460 body lines > 300; also pushes the file past
// file_length's 500-line warning threshold
enum MassiveType {
    static let member000 = 0
    static let member001 = 1
    static let member002 = 2
    static let member003 = 3
    static let member004 = 4
    static let member005 = 5
    static let member006 = 6
    static let member007 = 7
    static let member008 = 8
    static let member009 = 9
    static let member010 = 10
    static let member011 = 11
    static let member012 = 12
    static let member013 = 13
    static let member014 = 14
    static let member015 = 15
    static let member016 = 16
    static let member017 = 17
    static let member018 = 18
    static let member019 = 19
    static let member020 = 20
    static let member021 = 21
    static let member022 = 22
    static let member023 = 23
    static let member024 = 24
    static let member025 = 25
    static let member026 = 26
    static let member027 = 27
    static let member028 = 28
    static let member029 = 29
    static let member030 = 30
    static let member031 = 31
    static let member032 = 32
    static let member033 = 33
    static let member034 = 34
    static let member035 = 35
    static let member036 = 36
    static let member037 = 37
    static let member038 = 38
    static let member039 = 39
    static let member040 = 40
    static let member041 = 41
    static let member042 = 42
    static let member043 = 43
    static let member044 = 44
    static let member045 = 45
    static let member046 = 46
    static let member047 = 47
    static let member048 = 48
    static let member049 = 49
    static let member050 = 50
    static let member051 = 51
    static let member052 = 52
    static let member053 = 53
    static let member054 = 54
    static let member055 = 55
    static let member056 = 56
    static let member057 = 57
    static let member058 = 58
    static let member059 = 59
    static let member060 = 60
    static let member061 = 61
    static let member062 = 62
    static let member063 = 63
    static let member064 = 64
    static let member065 = 65
    static let member066 = 66
    static let member067 = 67
    static let member068 = 68
    static let member069 = 69
    static let member070 = 70
    static let member071 = 71
    static let member072 = 72
    static let member073 = 73
    static let member074 = 74
    static let member075 = 75
    static let member076 = 76
    static let member077 = 77
    static let member078 = 78
    static let member079 = 79
    static let member080 = 80
    static let member081 = 81
    static let member082 = 82
    static let member083 = 83
    static let member084 = 84
    static let member085 = 85
    static let member086 = 86
    static let member087 = 87
    static let member088 = 88
    static let member089 = 89
    static let member090 = 90
    static let member091 = 91
    static let member092 = 92
    static let member093 = 93
    static let member094 = 94
    static let member095 = 95
    static let member096 = 96
    static let member097 = 97
    static let member098 = 98
    static let member099 = 99
    static let member100 = 100
    static let member101 = 101
    static let member102 = 102
    static let member103 = 103
    static let member104 = 104
    static let member105 = 105
    static let member106 = 106
    static let member107 = 107
    static let member108 = 108
    static let member109 = 109
    static let member110 = 110
    static let member111 = 111
    static let member112 = 112
    static let member113 = 113
    static let member114 = 114
    static let member115 = 115
    static let member116 = 116
    static let member117 = 117
    static let member118 = 118
    static let member119 = 119
    static let member120 = 120
    static let member121 = 121
    static let member122 = 122
    static let member123 = 123
    static let member124 = 124
    static let member125 = 125
    static let member126 = 126
    static let member127 = 127
    static let member128 = 128
    static let member129 = 129
    static let member130 = 130
    static let member131 = 131
    static let member132 = 132
    static let member133 = 133
    static let member134 = 134
    static let member135 = 135
    static let member136 = 136
    static let member137 = 137
    static let member138 = 138
    static let member139 = 139
    static let member140 = 140
    static let member141 = 141
    static let member142 = 142
    static let member143 = 143
    static let member144 = 144
    static let member145 = 145
    static let member146 = 146
    static let member147 = 147
    static let member148 = 148
    static let member149 = 149
    static let member150 = 150
    static let member151 = 151
    static let member152 = 152
    static let member153 = 153
    static let member154 = 154
    static let member155 = 155
    static let member156 = 156
    static let member157 = 157
    static let member158 = 158
    static let member159 = 159
    static let member160 = 160
    static let member161 = 161
    static let member162 = 162
    static let member163 = 163
    static let member164 = 164
    static let member165 = 165
    static let member166 = 166
    static let member167 = 167
    static let member168 = 168
    static let member169 = 169
    static let member170 = 170
    static let member171 = 171
    static let member172 = 172
    static let member173 = 173
    static let member174 = 174
    static let member175 = 175
    static let member176 = 176
    static let member177 = 177
    static let member178 = 178
    static let member179 = 179
    static let member180 = 180
    static let member181 = 181
    static let member182 = 182
    static let member183 = 183
    static let member184 = 184
    static let member185 = 185
    static let member186 = 186
    static let member187 = 187
    static let member188 = 188
    static let member189 = 189
    static let member190 = 190
    static let member191 = 191
    static let member192 = 192
    static let member193 = 193
    static let member194 = 194
    static let member195 = 195
    static let member196 = 196
    static let member197 = 197
    static let member198 = 198
    static let member199 = 199
    static let member200 = 200
    static let member201 = 201
    static let member202 = 202
    static let member203 = 203
    static let member204 = 204
    static let member205 = 205
    static let member206 = 206
    static let member207 = 207
    static let member208 = 208
    static let member209 = 209
    static let member210 = 210
    static let member211 = 211
    static let member212 = 212
    static let member213 = 213
    static let member214 = 214
    static let member215 = 215
    static let member216 = 216
    static let member217 = 217
    static let member218 = 218
    static let member219 = 219
    static let member220 = 220
    static let member221 = 221
    static let member222 = 222
    static let member223 = 223
    static let member224 = 224
    static let member225 = 225
    static let member226 = 226
    static let member227 = 227
    static let member228 = 228
    static let member229 = 229
    static let member230 = 230
    static let member231 = 231
    static let member232 = 232
    static let member233 = 233
    static let member234 = 234
    static let member235 = 235
    static let member236 = 236
    static let member237 = 237
    static let member238 = 238
    static let member239 = 239
    static let member240 = 240
    static let member241 = 241
    static let member242 = 242
    static let member243 = 243
    static let member244 = 244
    static let member245 = 245
    static let member246 = 246
    static let member247 = 247
    static let member248 = 248
    static let member249 = 249
    static let member250 = 250
    static let member251 = 251
    static let member252 = 252
    static let member253 = 253
    static let member254 = 254
    static let member255 = 255
    static let member256 = 256
    static let member257 = 257
    static let member258 = 258
    static let member259 = 259
    static let member260 = 260
    static let member261 = 261
    static let member262 = 262
    static let member263 = 263
    static let member264 = 264
    static let member265 = 265
    static let member266 = 266
    static let member267 = 267
    static let member268 = 268
    static let member269 = 269
    static let member270 = 270
    static let member271 = 271
    static let member272 = 272
    static let member273 = 273
    static let member274 = 274
    static let member275 = 275
    static let member276 = 276
    static let member277 = 277
    static let member278 = 278
    static let member279 = 279
    static let member280 = 280
    static let member281 = 281
    static let member282 = 282
    static let member283 = 283
    static let member284 = 284
    static let member285 = 285
    static let member286 = 286
    static let member287 = 287
    static let member288 = 288
    static let member289 = 289
    static let member290 = 290
    static let member291 = 291
    static let member292 = 292
    static let member293 = 293
    static let member294 = 294
    static let member295 = 295
    static let member296 = 296
    static let member297 = 297
    static let member298 = 298
    static let member299 = 299
    static let member300 = 300
    static let member301 = 301
    static let member302 = 302
    static let member303 = 303
    static let member304 = 304
    static let member305 = 305
    static let member306 = 306
    static let member307 = 307
    static let member308 = 308
    static let member309 = 309
    static let member310 = 310
    static let member311 = 311
    static let member312 = 312
    static let member313 = 313
    static let member314 = 314
    static let member315 = 315
    static let member316 = 316
    static let member317 = 317
    static let member318 = 318
    static let member319 = 319
    static let member320 = 320
    static let member321 = 321
    static let member322 = 322
    static let member323 = 323
    static let member324 = 324
    static let member325 = 325
    static let member326 = 326
    static let member327 = 327
    static let member328 = 328
    static let member329 = 329
    static let member330 = 330
    static let member331 = 331
    static let member332 = 332
    static let member333 = 333
    static let member334 = 334
    static let member335 = 335
    static let member336 = 336
    static let member337 = 337
    static let member338 = 338
    static let member339 = 339
    static let member340 = 340
    static let member341 = 341
    static let member342 = 342
    static let member343 = 343
    static let member344 = 344
    static let member345 = 345
    static let member346 = 346
    static let member347 = 347
    static let member348 = 348
    static let member349 = 349
    static let member350 = 350
    static let member351 = 351
    static let member352 = 352
    static let member353 = 353
    static let member354 = 354
    static let member355 = 355
    static let member356 = 356
    static let member357 = 357
    static let member358 = 358
    static let member359 = 359
    static let member360 = 360
    static let member361 = 361
    static let member362 = 362
    static let member363 = 363
    static let member364 = 364
    static let member365 = 365
    static let member366 = 366
    static let member367 = 367
    static let member368 = 368
    static let member369 = 369
    static let member370 = 370
    static let member371 = 371
    static let member372 = 372
    static let member373 = 373
    static let member374 = 374
    static let member375 = 375
    static let member376 = 376
    static let member377 = 377
    static let member378 = 378
    static let member379 = 379
    static let member380 = 380
    static let member381 = 381
    static let member382 = 382
    static let member383 = 383
    static let member384 = 384
    static let member385 = 385
    static let member386 = 386
    static let member387 = 387
    static let member388 = 388
    static let member389 = 389
    static let member390 = 390
    static let member391 = 391
    static let member392 = 392
    static let member393 = 393
    static let member394 = 394
    static let member395 = 395
    static let member396 = 396
    static let member397 = 397
    static let member398 = 398
    static let member399 = 399
    static let member400 = 400
    static let member401 = 401
    static let member402 = 402
    static let member403 = 403
    static let member404 = 404
    static let member405 = 405
    static let member406 = 406
    static let member407 = 407
    static let member408 = 408
    static let member409 = 409
    static let member410 = 410
    static let member411 = 411
    static let member412 = 412
    static let member413 = 413
    static let member414 = 414
    static let member415 = 415
    static let member416 = 416
    static let member417 = 417
    static let member418 = 418
    static let member419 = 419
    static let member420 = 420
    static let member421 = 421
    static let member422 = 422
    static let member423 = 423
    static let member424 = 424
    static let member425 = 425
    static let member426 = 426
    static let member427 = 427
    static let member428 = 428
    static let member429 = 429
    static let member430 = 430
    static let member431 = 431
    static let member432 = 432
    static let member433 = 433
    static let member434 = 434
    static let member435 = 435
    static let member436 = 436
    static let member437 = 437
    static let member438 = 438
    static let member439 = 439
    static let member440 = 440
    static let member441 = 441
    static let member442 = 442
    static let member443 = 443
    static let member444 = 444
    static let member445 = 445
    static let member446 = 446
    static let member447 = 447
    static let member448 = 448
    static let member449 = 449
    static let member450 = 450
    static let member451 = 451
    static let member452 = 452
    static let member453 = 453
    static let member454 = 454
    static let member455 = 455
    static let member456 = 456
    static let member457 = 457
    static let member458 = 458
    static let member459 = 459
}
