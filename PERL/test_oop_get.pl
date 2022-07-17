#!/usr/bin/perl

use strict;
use MyClass;

# создаем новый объект
# в конструктор можно было передать дополнительные аргументы
# которые шли бы в sub new() следом за именем класса

# my $cl = new MyClass(); # олдскульный стиль
my $cl = MyClass->new();

# доступ к имени можно получить напрямую
print "Name:               ".$cl->{name}."\n";
# но правильнее делать это через гетер
# аналогично вызову MyClass::get_name($cl, другие-аргументы);
print "get_name() returns: ".$cl->get_name()."\n";
