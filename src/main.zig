
const std=@import("std");

const win32=@cImport({
    @cInclude("windows.h");
});

const print=std.debug.print;

const width=58;
const height=26;

const GameStateEnum=enum{
    Operation,//游戏中
    HitWall,//撞墙了
    HitBody,//撞到自己身体了
    WIN,//胜利
};

//方向类型
const DirectionEnum = enum {
    up,//上
    down,//下
    left,//左
    right,//右
};

const Point=struct{
    x:i16,
    y:i16,
};

//蛇妖~~
const SnakeType=struct{
    Head:*SnakeNode,
    Direction:DirectionEnum,
};

const SnakeNode=struct{
    x:i16,
    y:i16,
    next:?*SnakeNode,
};

var hOutput:win32.HANDLE=undefined;//输出句柄
var snake:SnakeType=undefined;//蛇对象
var game_state:GameStateEnum=undefined;//游戏状态
var fruits:Point=undefined;//果实坐标
var score:i32=undefined;//游戏得分

//设置光标位置
fn SetCursorPos(x:i16,y:i16) void {
    const coord=win32.COORD{.X=x,.Y=y};
    
    _=win32.SetConsoleCursorPosition(hOutput,coord);
}

//取蛇的尾头节点
fn GetEndHeadNode() *SnakeNode{
    var index=snake.Head;
    while(index.next.?.next!=null):(index=index.next.?){ }
    return index;
}

//取蛇的尾节点
fn GetEndNode() *SnakeNode{
    var index=snake.Head;
    while(index.next!=null):(index=index.next.?){ }
    return index;
}

//判断坐标是否在蛇身上
fn IsPosOnBody(x:i16,y:i16)bool{
    var current:?*SnakeNode = snake.Head;
    while (current) |node| {
        const next = node.next; // 保存下一个节点
        //allocator.destroy(node); // 释放当前节点
        if(node.x==x and node.y==y){
            return true;
        }
        current = next; // 移动到下一个节点
    }
    return false;
}

//生成果实坐标
fn GenerateFruits() !Point {
    //初始化分配器
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var point_list=std.ArrayList(Point).init(allocator);
    defer point_list.deinit(); // 释放内存
    
    for(1..width-2) | x | {
        for(1..height-2) | y | {
            if(!IsPosOnBody(@intCast(x),@intCast(y))){
                try point_list.append(Point{.x = @intCast(x),.y = @intCast(y)});
            }
        }
    }
    // 初始化随机数生成器
    var prng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp()));
    const random = prng.random(); // 获取随机数接口

    return point_list.items[random.intRangeAtMost(usize, 0, point_list.items.len-1)];
}

//是否满屏
fn IsFull()bool{
    for(1..width-2) | x | {
        for(1..height-2) | y | {
            if(!IsPosOnBody(@intCast(x),@intCast(y))){
                return false;
            }
        }
    }
    return true;
}

pub fn GameStart() !void {
    SetCursorPos(0,0);
    for(1..width) | _ | {
        print("#",.{});
    }
    SetCursorPos(0,1);
    for(1..height-1) | i |{
        print("#",.{});
        for(1..width-2) | _ |{
            print(" ",.{});
        }
        print("#",.{});
        SetCursorPos(0,@intCast(i+1));
    }
    SetCursorPos(0,height-1);
    for(1..width) | _ | {
        print("#",.{});
    }
    
    //初始化游戏信息
    score=0;
    
    //初始化分配器
    var gpa=std.heap.GeneralPurposeAllocator(.{}){};
    const allocator=gpa.allocator();
    var temp:*SnakeNode=undefined;
    
    //初始化蛇
    snake=SnakeType{
        .Head = try allocator.create(SnakeNode),
        .Direction = DirectionEnum.right,
    };
    temp=snake.Head;
    
    temp.x=20;temp.y=4;
    temp.next=try allocator.create(SnakeNode);
    temp=temp.next.?;
    
    temp.x=19;temp.y=4;
    temp.next=try allocator.create(SnakeNode);
    temp=temp.next.?;
    
    temp.x=18;temp.y=4;
    temp.next=try allocator.create(SnakeNode);
    temp=temp.next.?;
    
    temp.x=17;temp.y=4;
    temp.next=try allocator.create(SnakeNode);
    temp=temp.next.?;
    
    temp.x=16;temp.y=4;
    temp.next=null;
    
    SetCursorPos(20, 4);print("x", .{});
    SetCursorPos(19, 4);print("x", .{});
    SetCursorPos(18, 4);print("x", .{});
    SetCursorPos(17, 4);print("x", .{});
    SetCursorPos(16, 4);print("x", .{});
    
    fruits=try GenerateFruits();
    SetCursorPos(fruits.x, fruits.y);print("*", .{});
    
    game_state=GameStateEnum.Operation;
    
    while(game_state==GameStateEnum.Operation){
        //蛇移动
        switch (snake.Direction) {
            DirectionEnum.up=>{
                temp=snake.Head;
                
                if(temp.y-1==0){
                    game_state=GameStateEnum.HitWall;
                    continue;
                }else if(IsPosOnBody(temp.x, temp.y-1)){
                    game_state=GameStateEnum.HitBody;
                    continue;
                }
                
                if(temp.x==fruits.x and temp.y-1==fruits.y){
                    snake.Head=try allocator.create(SnakeNode);
                    snake.Head.next=temp;
                    snake.Head.x=fruits.x;
                    snake.Head.y=fruits.y;
                    SetCursorPos(snake.Head.x,snake.Head.y);
                    print("x", .{});
                    
                    fruits=try GenerateFruits();
                    SetCursorPos(fruits.x,fruits.y);
                    print("*", .{});
                    
                    score+=1;
                    
                    if(IsFull()){
                        game_state=GameStateEnum.WIN;
                        continue;
                    }
                }else{
                    snake.Head=try allocator.create(SnakeNode);
                    snake.Head.next=temp;
                    snake.Head.x=temp.x;
                    snake.Head.y=temp.y-1;
                    SetCursorPos(snake.Head.x,snake.Head.y);
                    print("x", .{});
                    
                    const temp2=GetEndHeadNode();
                    SetCursorPos(temp2.next.?.x,temp2.next.?.y);
                    print(" ", .{});
                    allocator.destroy(temp2.next.?);
                    temp2.next=null;
                }
                
            },
            DirectionEnum.down=>{
                temp=snake.Head;
                
                if(temp.y+1==height-1){
                    game_state=GameStateEnum.HitWall;
                    continue;
                }else if(IsPosOnBody(temp.x, temp.y+1)){
                    game_state=GameStateEnum.HitBody;
                    continue;
                }
                
                if(temp.x==fruits.x and temp.y+1==fruits.y){
                    snake.Head=try allocator.create(SnakeNode);
                    snake.Head.next=temp;
                    snake.Head.x=fruits.x;
                    snake.Head.y=fruits.y;
                    SetCursorPos(snake.Head.x,snake.Head.y);
                    print("x", .{});
                    
                    fruits=try GenerateFruits();
                    SetCursorPos(fruits.x,fruits.y);
                    print("*", .{});
                    
                    score+=1;
                    
                    if(IsFull()){
                        game_state=GameStateEnum.WIN;
                        continue;
                    }
                }else{
                    snake.Head=try allocator.create(SnakeNode);
                    snake.Head.next=temp;
                    snake.Head.x=temp.x;
                    snake.Head.y=temp.y+1;
                    SetCursorPos(snake.Head.x,snake.Head.y);
                    print("x", .{});
                    
                    const temp2=GetEndHeadNode();
                    SetCursorPos(temp2.next.?.x,temp2.next.?.y);
                    print(" ", .{});
                    allocator.destroy(temp2.next.?);
                    temp2.next=null;
                }
            },
            DirectionEnum.left=>{
                temp=snake.Head;
                
                if(temp.x-1==0){
                    game_state=GameStateEnum.HitWall;
                    continue;
                }else if(IsPosOnBody(temp.x-1, temp.y)){
                    game_state=GameStateEnum.HitBody;
                    continue;
                }
                
                if(temp.x-1==fruits.x and temp.y==fruits.y){
                    snake.Head=try allocator.create(SnakeNode);
                    snake.Head.next=temp;
                    snake.Head.x=fruits.x;
                    snake.Head.y=fruits.y;
                    SetCursorPos(snake.Head.x,snake.Head.y);
                    print("x", .{});
                    
                    fruits=try GenerateFruits();
                    SetCursorPos(fruits.x,fruits.y);
                    print("*", .{});
                    
                    score+=1;
                    
                    if(IsFull()){
                        game_state=GameStateEnum.WIN;
                        continue;
                    }
                }else{
                    snake.Head=try allocator.create(SnakeNode);
                    snake.Head.next=temp;
                    snake.Head.x=temp.x-1;
                    snake.Head.y=temp.y;
                    SetCursorPos(snake.Head.x,snake.Head.y);
                    print("x", .{});
                    
                    const temp2=GetEndHeadNode();
                    SetCursorPos(temp2.next.?.x,temp2.next.?.y);
                    print(" ", .{});
                    allocator.destroy(temp2.next.?);
                    temp2.next=null;
                }
            },
            DirectionEnum.right=>{
                temp=snake.Head;
                
                if(temp.x+1==width-2){
                    game_state=GameStateEnum.HitWall;
                    continue;
                }else if(IsPosOnBody(temp.x+1, temp.y)){
                    game_state=GameStateEnum.HitBody;
                    continue;
                }
                
                
                if(temp.x+1==fruits.x and temp.y==fruits.y){
                    snake.Head=try allocator.create(SnakeNode);
                    snake.Head.next=temp;
                    snake.Head.x=fruits.x;
                    snake.Head.y=fruits.y;
                    SetCursorPos(snake.Head.x,snake.Head.y);
                    print("x", .{});
                    
                    fruits=try GenerateFruits();
                    SetCursorPos(fruits.x,fruits.y);
                    print("*", .{});
                    
                    score+=1;
                    
                    if(IsFull()){
                        game_state=GameStateEnum.WIN;
                        continue;
                    }
                }else{
                    snake.Head=try allocator.create(SnakeNode);
                    snake.Head.next=temp;
                    snake.Head.x=temp.x+1;
                    snake.Head.y=temp.y;
                    SetCursorPos(snake.Head.x,snake.Head.y);
                    print("x", .{});
                    
                    const temp2=GetEndHeadNode();
                    SetCursorPos(temp2.next.?.x,temp2.next.?.y);
                    print(" ", .{});
                    allocator.destroy(temp2.next.?);
                    temp2.next=null;
                }
            },
        }
        
        SetCursorPos(70, 14);
        print("                                          ",.{});
        SetCursorPos(70, 14);
        print("Score:{}",.{score});
        
        const key_w_state=win32.GetAsyncKeyState('W');
        const key_s_state=win32.GetAsyncKeyState('S');
        const key_a_state=win32.GetAsyncKeyState('A');
        const key_d_state=win32.GetAsyncKeyState('D');
        
        SetCursorPos(70, 15);
        print("                                          ",.{});
        SetCursorPos(70, 15);
        print("KeyState: w:{},s:{},a:{},d:{}",.{key_w_state,key_s_state,key_a_state,key_d_state});
        
        if(key_w_state==-32767 and key_s_state!=-32767 and key_a_state!=-32767 and key_d_state!=-32767 and snake.Direction!=DirectionEnum.down){
            snake.Direction=DirectionEnum.up;
        }else if(key_w_state!=-32767 and key_s_state==-32767 and key_a_state!=-32767 and key_d_state!=-32767 and snake.Direction!=DirectionEnum.up){
            snake.Direction=DirectionEnum.down;
        }else if(key_w_state!=-32767 and key_s_state!=-32767 and key_a_state==-32767 and key_d_state!=-32767 and snake.Direction!=DirectionEnum.right){
            snake.Direction=DirectionEnum.left;
        }else if(key_w_state!=-32767 and key_s_state!=-32767 and key_a_state!=-32767 and key_d_state==-32767 and snake.Direction!=DirectionEnum.left){
            snake.Direction=DirectionEnum.right;
        }
        
        std.Thread.sleep(200*std.time.ns_per_ms);
    }
    
    //内存释放
    var current:?*SnakeNode = snake.Head;
    while (current) |node| {//对可选类型解构
        const next = node.next; // 保存下一个节点
        allocator.destroy(node); // 释放当前节点
        current = next; // 移动到下一个节点
    }
}

pub fn main() !void {
    _=win32.SetConsoleTitleA("Greedy Snake");
    
    hOutput=win32.GetStdHandle(win32.STD_OUTPUT_HANDLE);
    
    var CursorInfo=win32.CONSOLE_CURSOR_INFO{};
    _=win32.GetConsoleCursorInfo(hOutput,&CursorInfo);//取光标是否可见
    CursorInfo.bVisible=win32.FALSE;//设置光标不可见
    _=win32.SetConsoleCursorInfo(hOutput,&CursorInfo);
    
    while(true){
        try GameStart();
    }
}
